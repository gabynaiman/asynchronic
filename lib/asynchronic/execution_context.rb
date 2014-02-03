module Asynchronic
  class ExecutionContext

    attr_reader :data_store
    attr_reader :queue_engine
    attr_reader :default_queue
    
    def initialize(data_store, queue_engine, default_queue=:default)
      @data_store = data_store
      @queue_engine = queue_engine
      @default_queue = default_queue
    end

    def [](key)
      data_store.get key
    end

    def []=(key, value)
      data_store.set key, value
    end

    def enqueue(msg, queue=nil)
      queue_engine[queue || default_queue].push msg
    end

    def queue(name)
      queue_engine[name]
    end

    def define_job(*args, &block)
      specification = Specification.new(*args, &block)
      self[Job::Lookup.new(specification).job] = specification
      Job.new specification, self
    end

    def load_job(id)
      Job.new self[id], self
    end

  end
end