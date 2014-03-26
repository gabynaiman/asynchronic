module Asynchronic
  class Process

    attr_reader :id

    def initialize(environment, id)
      @environment = environment
      @id = Asynchronic::DataStore::Key.new id
    end

    def job
      type.new self
    end

    def type
      @environment[id[:type]]
    end

    def params
      Asynchronic::DataStore::ScopedStore.new(@environment.data_store, id[:params]).readonly
    end

    def data
      Asynchronic::DataStore::ScopedStore.new @environment.data_store, id[:data]
    end

    def children
      @environment.data_store.keys(id[:children]).
        map { |k| Asynchronic::DataStore::Key.new k }.
        select { |k| k.sections.count == id[:children].sections.count + 2 && k.match(/type$/) }.
        inject(HashWithIndiferentAccess.new) do |hash, key|
          name = Object.const_get(key.sections[-2]) rescue key.sections[-2]
          hash[name] = Process.new @environment, id[:children][name]
          hash
        end
    end

    def enqueue
      @environment.enqueue id
    end

    def create_child(type, params={})
      name = params.delete(:name) || type
      pid = id[:children][name]
      ProcessBuilder.build @environment, type, params.merge(pid: pid)
    end

    def self.create(environment, type, params={})
      ProcessBuilder.build environment, type, params
    end

    # STATUSES = [:pending, :queued, :running, :waiting, :completed, :aborted]

    # TIME_TRACKING_MAP = {
    #   queued: :queued_at,
    #   running: :started_at,
    #   completed: :finalized_at,
    #   aborted: :finalized_at
    # }

    # extend Forwardable

    # def_delegators :job, :id, :name, :queue
    # def_delegators :data, :[]

    # attr_reader :job
    # attr_reader :env

    # def initialize(job, env)
    #   @job = job
    #   @env = env
    # end

    # def pid
    #   lookup.id
    # end

    # def data
    #   parent ? parent.data : env.data_store.to_hash(lookup.data).with_indiferent_access
    # end

    # def merge(data)
    #   parent ? parent.merge(data) : env.data_store.merge(lookup.data, data)
    # end

    # def enqueue(data={})
    #   merge data
    #   env.enqueue lookup.id, queue
    #   update_status :queued

    #   lookup.id
    # end

    # def execute
    #   run
    #   wakeup
    # end

    # def wakeup
    #   if waiting?
    #     if processes.any?(&:aborted?)
    #       abort Error.new "Error caused by #{processes.select(&:aborted?).map{|p| p.job.name}.join(', ')}"
    #     else
    #       if processes.all?(&:completed?)
    #         update_status :completed 
    #       else
    #         processes.select(&:ready?).each { |p| p.enqueue }
    #       end
    #     end
    #   end

    #   parent.wakeup if parent && finalized?
    # end

    # def error
    #   env[lookup.error]
    # end

    # def status
    #   env[lookup.status] || :pending
    # end

    # STATUSES.each do |status|
    #   define_method "#{status}?" do
    #     self.status == status
    #   end
    # end

    # def ready?
    #   pending? && dependencies.all?(&:completed?)
    # end

    # def finalized?
    #   completed? || aborted?
    # end

    # def processes(name=nil)
    #   processes = env.data_store.keys(lookup.jobs).
    #     select { |k| k.match Regexp.new("^#{lookup.jobs[Asynchronic::UUID_REGEXP]}$") }.
    #     map { |k| env.load_process k }

    #   name ? processes.detect { |p| p.name == name.to_s } : processes
    # end

    # def parent
    #   @parent ||= Process.new env[job.parent], env if job.parent
    # end

    # def dependencies
    #   @dependencies ||= parent.processes.select { |p| job.dependencies.include? p.name }
    # end

    # def created_at
    #   env[lookup.created_at]
    # end

    # def queued_at
    #   env[lookup.queued_at]
    # end

    # def started_at
    #   env[lookup.started_at]
    # end

    # def finalized_at
    #   env[lookup.finalized_at]
    # end

    # private

    # def run
    #   update_status :running
    #   Runtime.evaluate self
    #   update_status :waiting
    # rescue Exception => ex
    #   message = "Failed job #{job.name} (#{lookup.id})\n#{ex.class} #{ex.message}\n#{ex.backtrace.join("\n")}"
    #   Asynchronic.logger.error('Asynchronic') { message }
    #   abort ex
    # end

    # def update_status(status)
    #   Asynchronic.logger.info('Asynchronic') { "#{status.to_s.capitalize} #{job.name} (#{lookup.id})" }
    #   env[lookup.status] = status
    #   env[lookup.send(TIME_TRACKING_MAP[status])] = Time.now if TIME_TRACKING_MAP.key? status
    # end

    # def abort(exception)
    #   env[lookup.error] = Error.new(exception)
    #   update_status :aborted
    # end

    # def lookup
    #   @lookup ||= job.lookup
    # end

  end
end