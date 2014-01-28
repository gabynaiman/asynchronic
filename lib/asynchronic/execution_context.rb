module Asynchronic
  class ExecutionContext

    attr_reader :queue_engine
    attr_reader :data_store
    
    def initialize(queue_engine, data_store)
      @queue_engine = queue_engine
      @data_store = data_store
    end

    def [](key)
      Key.new(key, data_store)
    end

    def enqueue(job, queue, data={})
      self[job.id].set job
      self[job.id].merge data
      queue_engine[queue].push job.id
    end

    def queue(name)
      @queue_engine[name]
    end

  end
end