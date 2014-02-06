module WorkerExamples

  let(:env) { Asynchronic::Environment.new data_store, queue_engine }
  let(:queue_name) { :test_worker }
  let(:queue) { env.queue queue_name }

  def enqueue_processes
    processes = 5.times.map do
      env.build_process(WorkerJob, queue: :test_worker).tap(&:enqueue)
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
    processes = enqueue_processes

    Asynchronic::Worker.start :test_worker, env do |worker|
      loop { break if worker.queue.empty? }
      worker.stop 
    end
    
    processes.each { |p| p.must_be :completed? }   
  end

end