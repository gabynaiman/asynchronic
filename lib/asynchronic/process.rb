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

    ATTRIBUTE_NAMES = [:type, :name, :queue, :status, :dependencies, :data, :result, :error] | TIME_TRACKING_MAP.values.uniq

    attr_reader :id

    def initialize(environment, id, &block)
      @environment = environment
      @id = DataStore::Key.new id
      instance_eval &block if block_given?
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
      type.new self
    end

    def [](process_name)
      processes.detect { |p| p.name == process_name }
    end

    def processes
      data_store.scoped(:processes).keys.
        select { |k| k.sections.count == 2 && k.match(/name$/) }.
        sort.map { |k| Process.new environment, id[:processes][k.remove_last] }
    end

    def parent
      Process.new environment, id.remove_last(2) if id.nested?
    end

    def root
      id.nested? ? Process.new(environment, id.sections.first) : self
    end

    def real_error
      return nil unless error

      processes.each do |child|
        return child.real_error if child.error
      end

      error.message
    end

    def dependencies
      return [] unless parent
      data_store[:dependencies].map { |d| parent[d] }
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

    def set(key, value)
      self.data = self.data.merge key => value
    end

    def self.create(environment, type, params={})
      id = params.delete(:id) || SecureRandom.uuid

      Asynchronic.logger.debug('Asynchronic') { "Created process #{type} - #{id} - #{params}" }

      new(environment, id) do
        self.type = type
        self.name = params.delete(:alias) || type
        self.queue = params.delete(:queue) || type.queue || parent_queue
        self.dependencies = Array(params.delete(:dependencies)) | Array(params.delete(:dependency)) | infer_dependencies(params)
        self.params = params
        self.data = {}
        pending!
      end
    end

    def self.all(environment)
      environment.data_store.keys.
        select { |k| k.sections.count == 2 && k.match(/created_at$/) }.
        sort_by { |k| environment.data_store[k] }.reverse.
        map { |k| Process.new environment, k.remove_last }
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
    end

    STATUSES.each do |status|
      define_method "#{status}!" do
        self.status = status
      end
    end

    def abort!(exception=nil)
      self.error = Error.new exception if exception
      aborted!
    end

    def run
      if root.aborted?
        abort!
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
        if processes.any?(&:aborted?)
          childs_with_errors = processes.select(&:error)
          error = childs_with_errors.any? ? "Error caused by #{childs_with_errors.map(&:name).join(', ')}" : nil
          abort! error
        elsif processes.all?(&:completed?)
          completed!
        else
          processes.each do |p|
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

  end
end