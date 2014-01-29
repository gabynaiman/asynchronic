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
      key = parent ? parent.local_jobs[id] : id
      context.enqueue key, queue
      update_status :queued
    end

    def execute
      update_status :running
      
      begin
        data = shared_data.to_hash.with_indiferent_access
        instance_exec data, &specification.block 
        shared_data.merge data
        wakeup
      rescue Exception => ex
        abort ex
      end

      parent.wakeup if parent
    end

    def wakeup
      update_status jobs.all?(&:completed?) ? :completed : :waiting
      jobs.select(&:ready?).each { |j| j.enqueue }
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

    def jobs(name=nil)
      jobs = local_jobs.keys.map { |k| Job.new context[k].get, context }
      name ? jobs.detect { |j| j.name == name  } : jobs
    end

    def parent
      Job.new context[specification.parent].get, context if specification.parent
    end

    def dependencies
      parent.jobs.select { |j| specification.dependencies.include? j.name }
    end

    def local_context
      context[id]
    end

    def shared_data
      parent ? parent.shared_data : local_context[:data]
    end

    def local_jobs
      local_context[:jobs]
    end

    private

    def define_job(name, options={}, &block)
      defaults = {
        parent: parent ? parent.local_jobs[id] : local_context.to_s,
        queue: queue
      }

      spec = Specification.new name, defaults.merge(options), &block
      local_jobs[spec.id].set spec
      Job.new spec, context
    end

    def update_status(status)
      local_context[:status].set status
    end

    def abort(exception)
      local_context[:error].set exception
      update_status :aborted
    end

  end
end