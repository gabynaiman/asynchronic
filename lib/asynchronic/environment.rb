module Asynchronic
  class Environment

    attr_reader :queue_engine
    attr_reader :data_store
    
    def initialize(queue_engine, data_store)
      @queue_engine = queue_engine
      @data_store = data_store
    end

    def [](key)
      data_store[key]
    end

    def []=(key, value)
      data_store[key] = value
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
      Asynchronic.logger.debug('Asynchronic') { "Building job #{job_class} - #{options}" }
      job_class.new(options).tap do |job|
        self[job.lookup.id] = job
        self[job.lookup.created_at] = Time.now
      end
    end

    def build_process(job_class, options={})
      Process.new build_job(job_class, options), self
    end

    def load_process(pid)
      Process.new self[pid], self
    end

    def processes
      data_store.keys.
        select { |k| k.match Regexp.new("job:#{Asynchronic::UUID_REGEXP}:created_at$") }.
        sort_by {|k| data_store.get k }.
        reverse.
        map { |k| load_process k.gsub(':created_at', '') }
    end

  end
end