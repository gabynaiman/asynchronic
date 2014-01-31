module Asynchronic
  class Job
    class Runtime
      
      attr_reader :job

      def initialize(job)
        @job = job
      end

      def evaluate
        data = job.data
        instance_exec data, &job.specification.block
        job.merge data
      end

      def define_job(name, options={}, &block)
        defaults = {
          parent: Lookup.new(job.specification).job,
          queue: job.queue
        }

        spec = Specification.new name, defaults.merge(options), &block
        job.context[Lookup.new(spec).job] = spec
        Job.new spec, job.context
      end
      
    end
  end
end