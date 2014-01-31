module Asynchronic
  class Job

    STATUSES = [:pending, :queued, :running, :waiting, :completed, :aborted]

    UUID_REGEXP = '[a-z\d]{8}-[a-z\d]{4}-[a-z\d]{4}-[a-z\d]{4}-[a-z\d]{12}'

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
      parent ? parent.data : context.data_store.to_hash(lookup.data).with_indiferent_access
    end

    def merge(data)
      parent ? parent.merge(data) : context.data_store.merge(lookup.data, data)
    end

    def enqueue(data={})
      merge data
      context.enqueue lookup.job, queue
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
          if jobs.all?(&:completed?)
            update_status :completed 
          else
            jobs.select(&:ready?).each { |j| j.enqueue }
          end
        end
      end

      parent.wakeup if parent && finalized?
    end

    def error
      context[lookup.error]
    end

    def status
      context[lookup.status] || :pending
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
      jobs = context.data_store.keys(lookup.jobs).
        select { |k| k.match Regexp.new("^#{lookup.jobs[UUID_REGEXP]}$") }.
        map { |k| Job.new context[k], context }

      name ? jobs.detect { |j| j.name == name  } : jobs
    end

    def parent
      @parent ||= Job.new context[specification.parent], context if specification.parent
    end

    def dependencies
      @dependencies ||= parent.jobs.select { |j| specification.dependencies.include? j.name }
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
      context[lookup.status] = status
    end

    def abort(exception)
      context[lookup.error] = Error.new(exception)
      update_status :aborted
    end

    def lookup
      @lookup ||= Lookup.new specification
    end

  end
end