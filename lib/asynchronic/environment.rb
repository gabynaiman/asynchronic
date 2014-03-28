module Asynchronic
  class Environment

    attr_reader :queue_engine
    attr_reader :data_store
    
    def initialize(queue_engine, data_store)
      @queue_engine = queue_engine
      @data_store = data_store.scoped :asynchronic
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
    
    # def processes
    #   data_store.keys.
    #     select { |k| k.match Regexp.new("job:#{Asynchronic::UUID_REGEXP}:created_at$") }.
    #     sort_by {|k| data_store.get k }.
    #     reverse.
    #     map { |k| load_process k.gsub(':created_at', '') }
    # end

  end
end