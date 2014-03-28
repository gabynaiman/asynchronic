module Asynchronic
  class Job

    def initialize(process)
      @process = process
    end

    def params
      @process.params
    end

    def result(reference)
      @process.processes(reference).result
    end

    def self.queue(name=nil)
      name ? @queue = name : @queue
    end

    private

    def async(type, params={})
      @process.nest type, params
    end

  end
end