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

    private

    def define_job(job_class, options={})
      defaults = {
        parent: process.job.lookup.id,
        queue: process.queue
      }
      
      #Ver si te puede mover al build de context (context.build_job job_class, options)
      job = job_class.new defaults.merge(options)
      process.context[job.lookup.id] = job
    end
    
    def data
      @data
    end

  end
end