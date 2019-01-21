module Asynchronic
  class Job

    def initialize(process)
      @process = process
    end

    def params
      @process.params
    end

    def result(reference)
      @process[reference].result
    end

    def self.queue(name=nil)
      name ? @queue = name : @queue
    end

    def self.enqueue(params={})
      process = Asynchronic.environment.create_process self, params
      process.enqueue
      process.id
    end

    private

    attr_reader :process

    def async(type, params={})
      process.nest type, params
      nil
    end

    def get(key)
      process.get key
    end

    def set(key, value)
      process.set key, value
    end

    def retry_when(exceptions, interval=1)
      yield
    rescue *exceptions => ex
      Asynchronic.logger.error(self.class) { "Retry for: #{ex.class} #{ex.message}" }
      sleep interval
      retry
    end

  end
end