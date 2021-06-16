class Asynchronic::Worker

  attr_reader :queue, :queue_name, :environment, :listener

  def initialize(queue_name, environment)
    @queue_name = queue_name
    @queue = environment.queue_engine[queue_name]
    @environment = environment
    @listener = environment.queue_engine.listener
  end

  def start
    Asynchronic.logger.info('Asynchronic') { "Starting worker of #{queue_name} (#{Process.pid})" }

    Signal.trap('QUIT') { stop }

    listener.listen(queue) do |pid|
      environment.load_process(pid).execute
    end
  end

  def stop
    Asynchronic.logger.info('Asynchronic') { "Stopping worker of #{queue_name} (#{Process.pid})" }
    listener.stop
  end

  def self.start(queue_name, &block)
    worker = new queue_name, Asynchronic.environment
    Thread.new { block.call(worker) } if block_given?
    worker.start
  end

end