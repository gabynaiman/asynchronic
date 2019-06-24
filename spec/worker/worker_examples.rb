module WorkerExamples

  let(:env) { Asynchronic::Environment.new queue_engine, data_store, notifier }
  let(:queue_name) { :test_worker }
  let(:queue) { env.queue queue_name }

  after do
    data_store.clear
    queue_engine.clear
  end

  def enqueue_processes
    processes = 5.times.map do
      env.create_process(WorkerJob, queue: :test_worker).tap(&:enqueue)
    end

    queue.must_enqueued processes
    processes.each { |p| p.must_be :queued? }

    processes
  end

  it 'Instance usage' do
    worker = Asynchronic::Worker.new :test_worker, env

    processes = enqueue_processes

    Thread.new do
      loop { break if queue.empty? }
      worker.stop 
    end

    worker.start

    processes.each { |p| p.must_be :completed? }
  end

  it 'Class usage' do
    Asynchronic.configure do |config|
      config.queue_engine = queue_engine
      config.data_store = data_store
    end

    processes = enqueue_processes

    Asynchronic::Worker.start :test_worker do |worker|
      loop { break if worker.queue.empty? }
      worker.stop 
    end
    
    processes.each { |p| p.must_be :completed? }   
  end

end