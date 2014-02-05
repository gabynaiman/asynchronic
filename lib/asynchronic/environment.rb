module Asynchronic
  class Environment

    attr_reader :data_store
    attr_reader :queue_engine
    attr_reader :default_queue
    
    #TODO: Mover default_queue al queue_engine
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

    def build_job(job_class, options={})
      job_class.new(options).tap do |job|
        self[job.lookup.id] = job
      end
    end

    def build_process(job_class)
      Process.new build_job(job_class), self
    end

    def load_process(id)
      Process.new self[id], self
    end

  end
end