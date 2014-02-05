module Asynchronic
  class Runtime
    
    attr_reader :process

    def initialize(process)
      @process = process
    end

    def evaluate
      @data = process.data
      process.job.local.each { |k,v| define_singleton_method(k) { v } }
      instance_eval &process.job.class.implementation
      process.merge @data
    end

    def self.evaluate(process)
      new(process).evaluate
    end

    private

    def define_job(job_class, options={})
      defaults = {
        parent: process.job.lookup.id,
        queue: process.queue
      }
      
      process.env.build_job job_class, defaults.merge(options)
    end
    
    def data
      @data
    end

  end
end