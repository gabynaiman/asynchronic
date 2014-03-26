module Asynchronic
  class Job

    def initialize(process)
      @process = process
    end

    def params
      @process.params
    end

    def data
      @process.data
    end

    def processes
      @process.processes
    end

    private

    def async(type, params={})
      @process.create_child(type, params).tap(&:enqueue)
    end

  end
end