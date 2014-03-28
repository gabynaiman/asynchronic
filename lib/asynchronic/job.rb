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

    def async(type, params={})
      @process.nest type, params
      nil
    end

  end
end