class Asynchronic::Worker

  attr_reader :queue
  attr_reader :queue_name
  attr_reader :env
  attr_reader :listener

  def initialize(queue_name, env)
    @queue_name = queue_name
    @queue = env.queue_engine[queue_name]
    @env = env
    @listener = env.queue_engine.listener
  end

  def start
    Asynchronic.logger.info('Asynchronic') { "Starting worker of #{queue_name} (#{Process.pid})" }

    Signal.trap('QUIT') { stop }
    
    listener.listen(queue) do |pid|
      env.load_process(pid).execute
    end
  end

  def stop
    Asynchronic.logger.info('Asynchronic') { "Stopping worker of #{@queue_name} (#{Process.pid})" }
    listener.stop
  end

  def self.start(queue_name, &block)
    worker = new queue_name, Asynchronic.environment
    Thread.new { block.call(worker) } if block_given?
    worker.start
  end

end