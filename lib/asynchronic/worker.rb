class Asynchronic::Worker

  attr_reader :queue
  attr_reader :env
  attr_reader :listener

  def initialize(queue_name, env)
    @queue = env.queue_engine[queue_name]
    @env = env
    @listener = env.queue_engine.listener
  end

  def start
    Signal.trap('INT') { stop }
    
    listener.listen(queue) do |job_key|
      env.load_process(job_key).execute
    end
  end

  def stop
    listener.stop
  end

  def self.start(queue_name, &block)
    worker = new queue_name, Asynchronic.environment
    Thread.new { block.call(worker) } if block_given?
    worker.start
  end

end