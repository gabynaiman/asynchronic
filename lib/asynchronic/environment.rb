module Asynchronic
  class Environment

    attr_reader :queue_engine
    attr_reader :data_store
    
    def initialize(queue_engine, data_store)
      @queue_engine = queue_engine
      @data_store = data_store
    end

    def [](key)
      data_store.get key
    end

    def []=(key, value)
      data_store.set key, value
    end

    def queue(name)
      queue_engine[name]
    end

    def default_queue
      queue(queue_engine.default_queue)
    end

    def enqueue(msg, queue=nil)
      queue(queue || queue_engine.default_queue).push msg
    end

    def build_job(job_class, options={})
      job_class.new(options).tap do |job|
        self[job.lookup.id] = job
      end
    end

    def build_process(job_class, options={})
      Process.new build_job(job_class, options), self
    end

    def load_process(job_key)
      Process.new self[job_key], self
    end

  end
end