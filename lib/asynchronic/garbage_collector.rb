module Asynchronic
  class GarbageCollector

    def initialize(environment, timeout)
      @environment = environment
      @timeout = timeout
      @running = false
      @conditions = {}
    end

    def start
      Asynchronic.logger.info('Asynchronic') { 'Starting GC' }

      Signal.trap('QUIT') { stop }

      @running = true

      while @running
        processes = environment.processes

        processes.each(&:abort_if_dead)

        conditions.each do |name, condition|
          Asynchronic.logger.info('Asynchronic') { "Running GC - #{name}" }
          begin
            processes.select(&condition).each(&:destroy)
          rescue => ex
            error_message = "#{ex.class}: #{ex.message}\n#{ex.backtrace.join("\n")}"
            Asynchronic.logger.error('Asynchronic') { error_message }
          end
        end

        wait
      end
    end

    def stop
      Asynchronic.logger.info('Asynchronic') { 'Stopping GC' }
      @running = false
    end

    def add_condition(name, &block)
      conditions[name] = block
    end

    def remove_condition(name)
      conditions.delete name
    end

    def conditions_names
      conditions.keys
    end

    private

    attr_reader :environment, :timeout, :conditions

    def wait
      Asynchronic.logger.info('Asynchronic') { 'Sleeping GC' }
      sleep timeout
    end

  end
end