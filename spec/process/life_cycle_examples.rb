module LifeCycleExamples
  
  let(:env) { Asynchronic::Environment.new queue_engine, data_store }

  let(:queue) { env.default_queue }

  def execute_work(queue)
    env.load_process(queue.pop).execute
  end

  def enqueue(process, data={})
    process.enqueue(data).must_equal process.job.lookup.id
  end

  it 'Basic' do
    process = env.build_process BasicJob

    process.must_be_initialized
    queue.must_be_empty

    enqueue process, input: 1

    process.must_be :queued?
    process.must_have input: 1
    queue.must_enqueued process

    execute_work queue

    process.must_be :completed?
    process.must_have input: 1, output: 2
    queue.must_be_empty
  end

  it 'Sequential' do
    process = env.build_process SequentialJob

    process.must_be_initialized
    queue.must_be_empty

    enqueue process, input: 50

    process.must_be :queued?
    process.processes.must_be_empty
    process.must_have input: 50
    queue.must_enqueued process

    execute_work queue

    process.must_be :waiting?
    process.processes(SequentialJob::Step1).must_be :queued?
    process.processes(SequentialJob::Step2).must_be :pending?
    process.must_have input: 50
    queue.must_enqueued process.processes(SequentialJob::Step1)

    execute_work queue

    process.must_be :waiting?
    process.processes(SequentialJob::Step1).must_be :completed?
    process.processes(SequentialJob::Step2).must_be :queued?
    process.must_have input: 50, partial: 500
    queue.must_enqueued process.processes(SequentialJob::Step2)

    execute_work queue

    process.must_be :completed?
    process.processes(SequentialJob::Step1).must_be :completed?
    process.processes(SequentialJob::Step2).must_be :completed?
    process.must_have input: 50, partial: 500, output: 5
    queue.must_be_empty
  end

  it 'Graph' do
    process = env.build_process GraphJob

    process.must_be_initialized
    queue.must_be_empty

    enqueue process, input: 100

    process.must_be :queued?
    process.processes.must_be_empty
    process.must_have input: 100
    queue.must_enqueued process

    execute_work queue

    process.must_be :waiting?
    process.processes(GraphJob::Sum).must_be :queued?
    process.processes(GraphJob::TenPercent).must_be :pending?
    process.processes(GraphJob::TwentyPercent).must_be :pending?
    process.processes(GraphJob::Total).must_be :pending?
    process.must_have input: 100
    queue.must_enqueued process.processes(GraphJob::Sum)
    
    execute_work queue

    process.must_be :waiting?
    process.processes(GraphJob::Sum).must_be :completed?
    process.processes(GraphJob::TenPercent).must_be :queued?
    process.processes(GraphJob::TwentyPercent).must_be :queued?
    process.processes(GraphJob::Total).must_be :pending?
    process.must_have input: 100, sum: 200
    queue.must_enqueued [process.processes(GraphJob::TenPercent), process.processes(GraphJob::TwentyPercent)]

    2.times { execute_work queue }

    process.must_be :waiting?
    process.processes(GraphJob::Sum).must_be :completed?
    process.processes(GraphJob::TenPercent).must_be :completed?
    process.processes(GraphJob::TwentyPercent).must_be :completed?
    process.processes(GraphJob::Total).must_be :queued?
    process.must_have input: 100, sum: 200, '10%' => 20, '20%' => 40
    queue.must_enqueued process.processes(GraphJob::Total)

    execute_work queue

    process.must_be :completed?
    process.processes(GraphJob::Sum).must_be :completed?
    process.processes(GraphJob::TenPercent).must_be :completed?
    process.processes(GraphJob::TwentyPercent).must_be :completed?
    process.processes(GraphJob::Total).must_be :completed?
    process.must_have input: 100, sum: 200, '10%' => 20, '20%' => 40, output: {'10%' => 20, '20%' => 40}
    queue.must_be_empty
  end

  it 'Parallel' do
    process = env.build_process ParallelJob

    process.must_be_initialized
    queue.must_be_empty

    enqueue process, input: 10, times: 3

    process.must_be :queued?
    process.processes.must_be_empty
    process.must_have input: 10, times: 3
    queue.must_enqueued process

    execute_work queue

    process.must_be :waiting?
    process.processes.each { |p| p.must_be :queued? }
    process.must_have input: 10, times: 3
    queue.must_enqueued process.processes

    3.times { execute_work queue }

    process.must_be :completed?
    process.processes.each { |p| p.must_be :completed? }
    hash = Hash[3.times.map { |i| ["key_#{i}", 10 * i] }]
    process.must_have hash.merge(input: 10, times: 3)
    queue.must_be_empty
  end

  it 'Nested' do
    process = env.build_process NestedJob

    process.must_be_initialized
    queue.must_be_empty

    enqueue process, input: 4

    process.must_be :queued?
    process.processes.must_be_empty
    process.must_have input: 4
    queue.must_enqueued process

    execute_work queue

    process.must_be :waiting?
    process.processes(NestedJob::Level1).must_be :queued?
    process.processes(NestedJob::Level1).processes.must_be_empty
    process.must_have input: 4
    queue.must_enqueued process.processes(NestedJob::Level1)

    execute_work queue

    process.must_be :waiting?
    process.processes(NestedJob::Level1).must_be :waiting?
    process.processes(NestedJob::Level1).processes(NestedJob::Level1::Level2).must_be :queued?
    process.must_have input: 5
    queue.must_enqueued process.processes(NestedJob::Level1).processes(NestedJob::Level1::Level2)

    execute_work queue

    process.must_be :completed?
    process.processes(NestedJob::Level1).must_be :completed?
    process.processes(NestedJob::Level1).processes(NestedJob::Level1::Level2).must_be :completed?
    process.must_have input: 5, output: 25
    queue.must_be_empty
  end

  it 'Dependency alias' do
    process = env.build_process DependencyAliasJob

    process.must_be_initialized
    queue.must_be_empty

    enqueue process

    process.must_be :queued?
    process.processes.must_be_empty
    process.data.must_be_empty
    queue.must_enqueued process

    execute_work queue

    process.must_be :waiting?
    process.processes(:word_1).must_be :queued?
    process.processes(:word_2).must_be :pending?
    process.processes(:word_3).must_be :pending?
    process.data.must_be_empty
    queue.must_enqueued process.processes(:word_1)

    execute_work queue

    process.must_be :waiting?
    process.processes(:word_1).must_be :completed?
    process.processes(:word_2).must_be :queued?
    process.processes(:word_3).must_be :pending?
    process.must_have text: 'Take'
    queue.must_enqueued process.processes(:word_2)

    execute_work queue

    process.must_be :waiting?
    process.processes(:word_1).must_be :completed?
    process.processes(:word_2).must_be :completed?
    process.processes(:word_3).must_be :queued?
    process.must_have text: 'Take it'
    queue.must_enqueued process.processes(:word_3)

    execute_work queue

    process.must_be :completed?
    process.processes(:word_1).must_be :completed?
    process.processes(:word_2).must_be :completed?
    process.processes(:word_3).must_be :completed?
    process.must_have text: 'Take it easy'
    queue.must_be_empty
  end
  
  it 'Custom queue' do
    process = env.build_process CustomQueueJob

    process.must_be_initialized
    
    env.queue(:queue_1).must_be_empty
    env.queue(:queue_2).must_be_empty
    env.queue(:queue_3).must_be_empty

    enqueue process, input: 'hello'

    process.must_be :queued?
    process.processes.must_be_empty
    process.must_have input: 'hello'
    
    env.queue(:queue_1).must_enqueued process
    env.queue(:queue_2).must_be_empty
    env.queue(:queue_3).must_be_empty

    execute_work env.queue(:queue_1)

    process.must_be :waiting?
    process.processes(CustomQueueJob::Reverse).must_be :queued?
    process.must_have input: 'hello'
    
    env.queue(:queue_1).must_be_empty
    env.queue(:queue_2).must_enqueued process.processes(CustomQueueJob::Reverse)
    env.queue(:queue_3).must_be_empty

    execute_work env.queue(:queue_2)

    process.must_be :completed?
    process.processes(CustomQueueJob::Reverse).must_be :completed?
    process.must_have input: 'hello', output: 'olleh'
    
    env.queue(:queue_1).must_be_empty
    env.queue(:queue_2).must_be_empty
    env.queue(:queue_3).must_be_empty
  end

  it 'Exception' do
    process = env.build_process ExceptionJob

    process.must_be_initialized
    queue.must_be_empty

    enqueue process

    process.must_be :queued?
    queue.must_enqueued process

    execute_work queue

    process.must_be :aborted?
    process.error.must_be_instance_of Asynchronic::Error
    process.error.message.must_equal 'Error for test'
  end

  it 'Inner exception' do
    process = env.build_process InnerExceptionJob

    process.must_be_initialized
    queue.must_be_empty

    enqueue process

    process.must_be :queued?
    queue.must_enqueued process

    execute_work queue

    process.must_be :waiting?
    process.processes(ExceptionJob).must_be :queued?
    queue.must_enqueued process.processes(ExceptionJob)

    execute_work queue

    process.must_be :aborted?
    process.error.must_be_instance_of Asynchronic::Error
    process.error.message.must_equal 'Error caused by ExceptionJob'

    process.processes(ExceptionJob).must_be :aborted?
    process.processes(ExceptionJob).error.must_be_instance_of Asynchronic::Error
    process.processes(ExceptionJob).error.message.must_equal 'Error for test'
  end

end