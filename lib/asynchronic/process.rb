module Asynchronic
  class Process

    STATUSES = [:pending, :queued, :running, :waiting, :completed, :aborted]

    TIME_TRACKING_MAP = {
      pending: :created_at,
      queued: :queued_at,
      running: :started_at,
      completed: :finalized_at,
      aborted: :finalized_at
    }

    ATTRIBUTE_NAMES = [:type, :queue, :status, :dependencies, :result, :error] | TIME_TRACKING_MAP.values.uniq

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

    def params
      data_store.scoped(:params).readonly
    end

    def result
      data_store.lazy[:result]
    end

    def job
      type.new self
    end

    def processes(name=nil)
      index = data_store.scoped(:processes).keys.
        select { |k| k.sections.count == 2 && k.match(/type$/) }.
        inject(HashWithIndiferentAccess.new) do |hash, key|
          reference = Object.const_get(key.sections.first) rescue key.sections.first
          hash[reference] = Process.new environment, id[:processes][reference]
          hash
        end

      name ? index[name] : index.values
    end

    def parent
      Process.new environment, id.remove_last(2) if id.nested?
    end

    def dependencies
      return [] unless parent
      data_store[:dependencies].map { |d| parent.processes d }
    end

    def enqueue
      environment.enqueue id, queue || type.queue
      queued!
    end

    def execute
      run
      wakeup
    end

    def wakeup
      if waiting?
        if processes.any?(&:aborted?)
          abort! Error.new "Error caused by #{processes.select(&:aborted?).map{|p| p.id.sections.last}.join(', ')}"
        elsif processes.all?(&:completed?)
          completed!
        else
          processes.select(&:ready?).each(&:enqueue)
        end
      end

      parent.wakeup if parent && finalized?
    end

    def nest(type, params={})
      name = params.delete(:name) || type
      self.class.create @environment, type, params.merge(id: id[:processes][name])
    end

    def self.create(environment, type, params={})
      id = params.delete(:id) || SecureRandom.uuid

      Asynchronic.logger.debug('Asynchronic') { "Created process #{type} - #{id} - #{params}" }

      new(environment, id) do
        self.type = type
        self.queue = params.delete :queue
        self.dependencies = Array(params.delete(:dependencies)) | Array(params.delete(:dependency))
        self.params = params
        pending!
      end
    end

    private

    def environment
      @environment
    end

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

    def abort!(exception)
      self.error = Error.new exception
      aborted!
    end

    def run
      running!
      self.result = job.call
      waiting!
    rescue Exception => ex
      message = "Failed process #{type} (#{id})\n#{ex.class} #{ex.message}\n#{ex.backtrace.join("\n")}"
      Asynchronic.logger.error('Asynchronic') { message }
      abort! ex
    end

  end
end