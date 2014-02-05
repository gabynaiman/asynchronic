module Asynchronic
  class Environment

    attr_reader :data_store
    attr_reader :queue_engine
    
    def initialize(data_store, queue_engine)
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

    def build_process(job_class)
      Process.new build_job(job_class), self
    end

    def load_process(id)
      Process.new self[id], self
    end

  end
end