module Asynchronic
  class Process

    STATUSES = [:pending, :queued, :running, :waiting, :completed, :aborted]

    UUID_REGEXP = '[a-z\d]{8}-[a-z\d]{4}-[a-z\d]{4}-[a-z\d]{4}-[a-z\d]{12}'

    extend Forwardable

    def_delegators :job, :id, :name, :queue
    def_delegators :data, :[]

    attr_reader :job
    attr_reader :context

    def initialize(job, context)
      @job = job
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
      context.enqueue lookup.id, queue
      update_status :queued
    end

    def execute
      run
      wakeup
    end

    def wakeup
      if waiting?
        if processes.any?(&:aborted?)
          abort Error.new "Error caused by #{processes.select(&:aborted?).map{|p| p.job.class}.join(', ')}"
        else
          if processes.all?(&:completed?)
            update_status :completed 
          else
            processes.select(&:ready?).each { |p| p.enqueue }
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

    def processes(klass=nil)
      processes = context.data_store.keys(lookup.jobs).
        select { |k| k.match Regexp.new("^#{lookup.jobs[UUID_REGEXP]}$") }.
        map { |k| Process.new context[k], context }

      klass ? processes.detect { |p| p.job.is_a? klass } : processes
    end

    def parent
      @parent ||= Process.new context[job.parent], context if job.parent
    end

    def dependencies
      @dependencies ||= parent.processes.select { |p| job.dependencies.include? p.job.class }
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
      @lookup ||= job.lookup
    end

  end
end