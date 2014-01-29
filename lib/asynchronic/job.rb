module Asynchronic
  class Job

    STATUSES = [:pending, :queued, :running, :waiting, :completed, :aborted]

    extend Forwardable

    def_delegators :specification, :id, :name, :queue
    def_delegators :data, :[]

    attr_reader :specification
    attr_reader :context

    def initialize(specification, context)
      @specification = specification
      @context = context
    end

    def data
      shared_data.to_hash.with_indiferent_access
    end

    def enqueue(data={})
      shared_data.merge data
      context.enqueue local_context.to_s, queue
      update_status :queued
    end

    def execute
      run
      wakeup
    end

    def wakeup
      if waiting?
        if jobs.any?(&:aborted?)
          abort Error.new "Error caused by #{jobs.select(&:aborted?).map(&:name).join(', ')}"
        else
          update_status :completed if jobs.all?(&:completed?)
          jobs.select(&:ready?).each { |j| j.enqueue }
        end
      end

      parent.wakeup if parent && finalized?
    end

    def error
      local_context[:error].get
    end

    def status
      local_context[:status].get || :pending
    end

    STATUSES.each do |status|
      define_method "#{status}?" do
        self.status == status
      end
    end

    def ready?
      pending? && dependencies.all?(&:completed?)
    end

    def finalized?
      completed? || aborted?
    end

    def jobs(name=nil)
      # TODO: Mejorar la forma en que se identifican los jobs
      jobs = local_jobs.keys.map do |key| 
        spec = context[key].get
        spec.is_a?(Specification) ? Job.new(spec, context) : nil
      end.compact
      name ? jobs.detect { |j| j.name == name  } : jobs
    end

    def parent
      @parent ||= Job.new context[specification.parent].get, context if specification.parent
    end

    def dependencies
      @dependencies ||= parent.jobs.select { |j| specification.dependencies.include? j.name }
    end

    def local_context
      parent ? parent.local_jobs[id] : context[id]
    end

    def shared_data
      parent ? parent.shared_data : local_context[:data]
    end

    def local_jobs
      local_context[:jobs]
    end

    private

    def run
      update_status :running
      Runtime.new(self).evaluate
      update_status :waiting
    rescue Exception => ex
      abort ex
    end

    def update_status(status)
      local_context[:status].set status
    end

    def abort(exception)
      local_context[:error].set Error.new(exception)
      update_status :aborted
    end


    class Runtime

      attr_reader :job

      def initialize(job)
        @job = job
      end

      def evaluate
        data = job.shared_data.to_hash.with_indiferent_access
        instance_exec data, &job.specification.block
        job.shared_data.merge data
      end

      def define_job(name, options={}, &block)
        defaults = {
          parent: job.local_context.to_s,
          queue: job.queue
        }

        spec = Specification.new name, defaults.merge(options), &block
        job.local_jobs[spec.id].set spec
        Job.new spec, job.context
      end

    end

  end
end