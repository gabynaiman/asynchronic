module Asynchronic
  class Process

    STATUSES = [:pending, :queued, :running, :waiting, :completed, :aborted]

    TIME_TRACKING_MAP = {
      pending:   :created_at,
      queued:    :queued_at,
      running:   :started_at,
      completed: :finalized_at,
      aborted:   :finalized_at
    }

    ATTRIBUTE_NAMES = [:type, :name, :queue, :status, :dependencies, :data, :result, :error, :connection_name] | TIME_TRACKING_MAP.values.uniq

    AUTOMATIC_ABORTED_ERROR_MESSAGE = 'Automatic aborted before execution'
    CANCELED_ERROR_MESSAGE = 'Canceled'
    DEAD_ERROR_MESSAGE = 'Process connection broken'

    attr_reader :id

    def self.create(environment, type, params={})
      id = params.delete(:id) || SecureRandom.uuid

      Asynchronic.logger.debug('Asynchronic') { "Created process #{type} - #{id} - #{params}" }

      new(environment, id) do
        self.type = type
        self.name = (params.delete(:alias) || type).to_s
        self.queue = params.delete(:queue) || type.queue || parent_queue
        self.dependencies = Array(params.delete(:dependencies)) | Array(params.delete(:dependency)) | infer_dependencies(params)
        self.params = params
        self.data = {}
        pending!
      end
    end

    def self.all(environment)
      environment.data_store.keys
                            .select { |k| k.sections.count == 2 && k.match(/created_at$/) }
                            .sort_by { |k| environment.data_store[k] }
                            .reverse
                            .map { |k| Process.new environment, k.remove_last }
    end

    def initialize(environment, id, &block)
      @environment = environment
      @id = DataStore::Key[id]
      instance_eval(&block) if block_given?
    end

    ATTRIBUTE_NAMES.each do |attribute|
      define_method attribute do
        data_store[attribute]
      end
    end

    STATUSES.each do |status|
      define_method "#{status}?" do
        self.status == status
      end
    end

    def ready?
      pending? && dependencies.all?(&:completed?)
    end

    def finalized?
      completed? || aborted?
    end

    def cancel!
      abort! CANCELED_ERROR_MESSAGE
    end

    def dead?
      (running? && !connected?) || (!finalized? && processes.any?(&:dead?))
    end

    def abort_if_dead
      abort! DEAD_ERROR_MESSAGE if dead?
    end

    def destroy
      data_store.delete_cascade
    end

    def full_status
      processes.each_with_object(name => status) do |process, hash|
        hash.update(process.full_status)
      end
    end

    def params
      data_store.scoped(:params).no_lazy.readonly
    end

    def result
      data_store.lazy[:result]
    end

    def job
      @job ||= type.new self
    end

    def [](process_name)
      processes.detect { |p| p.name == process_name.to_s }
    end

    def processes
      data_store.scoped(:processes)
                .keys
                .select { |k| k.sections.count == 2 && k.match(/\|name$/) }
                .sort
                .map { |k| Process.new environment, id[:processes][k.remove_last] }
    end

    def parent
      Process.new environment, id.remove_last(2) if id.nested?
    end

    def root
      id.nested? ? Process.new(environment, id.sections.first) : self
    end

    def real_error
      return nil if !aborted?

      first_aborted_child = processes.select(&:aborted?).sort_by(&:finalized_at).first

      first_aborted_child ? first_aborted_child.real_error : error.message
    end

    def dependencies
      return [] if parent.nil? || data_store[:dependencies].empty?

      parent_processes = parent.processes.each_with_object({}) do |process, hash|
        hash[process.name] = process
      end

      data_store[:dependencies].map { |d| parent_processes[d.to_s] }
    end

    def enqueue
      queued!
      environment.enqueue id, queue
    end

    def execute
      run
      Asynchronic.retry_execution(self.class, 'wakeup') do
        wakeup
      end
    end

    def wakeup
      Asynchronic.logger.info('Asynchronic') { "Wakeup started #{type} (#{id})" }
      if environment.queue_engine.asynchronic?
        data_store.synchronize(id) { wakeup_children }
      else
        wakeup_children
      end
      Asynchronic.logger.info('Asynchronic') { "Wakeup finalized #{type} (#{id})" }

      parent.wakeup if parent && finalized?
    end

    def nest(type, params={})
      self.class.create environment, type, params.merge(id: id[:processes][processes.count])
    end

    def get(key)
      self.data[key]
    end

    def set(key, value)
      self.data = self.data.merge key => value
    end

    private

    attr_reader :environment

    def data_store
      @data_store ||= environment.data_store.scoped id
    end

    ATTRIBUTE_NAMES.each do |attribute|
      define_method "#{attribute}=" do |value|
        data_store[attribute] = value
      end
    end

    def params=(params)
      data_store.scoped(:params).merge params
    end

    def status=(status)
      Asynchronic.logger.info('Asynchronic') { "#{status.to_s.capitalize} #{type} (#{id})" }

      data_store[:status] = status
      data_store[TIME_TRACKING_MAP[status]] = Time.now if TIME_TRACKING_MAP.key? status

      environment.notifier.publish id, :status_changed, status
      environment.notifier.publish id, :finalized if finalized?
    end

    STATUSES.each do |status|
      define_method "#{status}!" do
        begin
          job.before_finalize if [:completed, :aborted].include?(status) && job.respond_to?(:before_finalize)
          self.status = status
        rescue Exception => exception
          self.error = Error.new exception unless error
          self.status = :aborted
        end
      end
    end

    def abort!(exception)
      self.error = Error.new exception
      aborted!
    end

    def run
      self.connection_name = Asynchronic.connection_name

      if root.aborted?
        abort! AUTOMATIC_ABORTED_ERROR_MESSAGE
      else
        running!
        self.result = job.call
        waiting!
      end

    rescue Exception => ex
      message = "Failed process #{type} (#{id})\n#{ex.class} #{ex.message}\n#{ex.backtrace.join("\n")}"
      Asynchronic.logger.error('Asynchronic') { message }
      Asynchronic.retry_execution(self.class, 'abort') do
        abort! ex
      end
    end

    def wakeup_children
      if waiting?
        children = processes # Cached child processes
        if children.any?(&:aborted?)
          childs_with_errors = children.select(&:error)
          error = childs_with_errors.any? ? "Error caused by #{childs_with_errors.map(&:name).join(', ')}" : nil
          abort! error
        elsif children.all?(&:completed?)
          completed!
        else
          children.each do |p|
            p.enqueue if p.ready?
          end
        end
      end
    end

    def infer_dependencies(params)
      params.values.select { |v| v.respond_to?(:proxy?) && v.proxy_class == DataStore::LazyValue }
                   .map { |v| Process.new(environment, v.data_store.scope).name }
    end

    def parent_queue
      parent.queue if parent
    end

    def connected?
      connection_name && environment.queue_engine.active_connections.include?(connection_name)
    rescue => ex
      Asynchronic.logger.error('Asynchronic') { "#{ex.message}\n#{ex.backtrace.join("\n")}" }
      true
    end

  end
end