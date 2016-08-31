module Asynchronic
  class Environment

    attr_reader :queue_engine
    attr_reader :data_store
    
    def initialize(queue_engine, data_store)
      @queue_engine = queue_engine
      @data_store = data_store
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

    def create_process(type, params={})
      Process.create self, type, params
    end

    def load_process(id)
      Process.new self, id
    end
    
    def processes
      Process.all self
    end

  end
end