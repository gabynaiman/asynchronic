module LifeCycleExamples
  
  let(:env) { Asynchronic::Environment.new queue_engine, data_store }

  let(:queue) { env.default_queue }

  def create(type, params={})
    env.create_process type, params
  end

  def execute(queue)
    env.load_process(queue.pop).execute
  end

  it 'Basic' do
    process = create BasicJob, input: 1

    process.must_be_initialized
    process.must_have_params input: 1
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_completed
    process.result.must_equal 2
    queue.must_be_empty
  end

  it 'Sequential' do
    process = create SequentialJob, input: 50

    process.must_be_initialized
    process.must_have_params input: 50
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process.processes(SequentialJob::Step1).must_be_queued
    process.processes(SequentialJob::Step1).must_have_params input: 50
    process.processes(SequentialJob::Step2).must_be_pending
    process.processes(SequentialJob::Step2).must_have_params input: nil
    queue.must_enqueued process.processes(SequentialJob::Step1)

    execute queue

    process.must_be_waiting
    process.processes(SequentialJob::Step1).must_be_completed
    process.processes(SequentialJob::Step1).result.must_equal 500
    process.processes(SequentialJob::Step2).must_be_queued
    process.processes(SequentialJob::Step2).must_have_params input: 500
    queue.must_enqueued process.processes(SequentialJob::Step2)

    execute queue

    process.must_be_completed
    process.result.must_equal 5
    process.processes(SequentialJob::Step2).must_be_completed
    process.processes(SequentialJob::Step2).result.must_equal 5
    queue.must_be_empty
  end

  it 'Graph' do
    process = create GraphJob, input: 100

    process.must_be_initialized
    process.must_have_params input: 100
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process.processes(GraphJob::Sum).must_be_queued
    process.processes(GraphJob::Sum).must_have_params input: 100
    process.processes(GraphJob::TenPercent).must_be_pending
    process.processes(GraphJob::TenPercent).must_have_params input: nil
    process.processes(GraphJob::TwentyPercent).must_be_pending
    process.processes(GraphJob::TwentyPercent).must_have_params input: nil
    process.processes(GraphJob::Total).must_be_pending
    process.processes(GraphJob::Total).must_have_params '10%' => nil, '20%' => nil
    queue.must_enqueued process.processes(GraphJob::Sum)
    
    execute queue

    process.must_be_waiting
    process.processes(GraphJob::Sum).must_be_completed
    process.processes(GraphJob::Sum).result.must_equal 200
    process.processes(GraphJob::TenPercent).must_be_queued
    process.processes(GraphJob::TenPercent).must_have_params input: 200
    process.processes(GraphJob::TwentyPercent).must_be_queued
    process.processes(GraphJob::TwentyPercent).must_have_params input: 200
    process.processes(GraphJob::Total).must_be_pending
    queue.must_enqueued [process.processes(GraphJob::TenPercent), process.processes(GraphJob::TwentyPercent)]

    2.times { execute queue }

    process.must_be_waiting
    process.processes(GraphJob::TenPercent).must_be_completed
    process.processes(GraphJob::TenPercent).result.must_equal 20
    process.processes(GraphJob::TwentyPercent).must_be_completed
    process.processes(GraphJob::TwentyPercent).result.must_equal 40
    process.processes(GraphJob::Total).must_be_queued
    queue.must_enqueued process.processes(GraphJob::Total)

    execute queue

    process.must_be_completed
    process.result.must_equal '10%' => 20, '20%' => 40
    process.processes(GraphJob::Total).must_be_completed
    process.processes(GraphJob::Total).result.must_equal '10%' => 20, '20%' => 40
    queue.must_be_empty
  end

  it 'Parallel' do
		skip
    process = create ParallelJob, input: 10, times: 3

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    process.processes.must_be_empty
    process.must_have input: 10, times: 3
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process.processes.each { |p| p.must_be_queued }
    process.must_have input: 10, times: 3
    queue.must_enqueued process.processes

    3.times { execute queue }

    process.must_be_completed
    process.processes.each { |p| p.must_be_completed }
    hash = Hash[3.times.map { |i| ["key_#{i}", 10 * i] }]
    process.must_have hash.merge(input: 10, times: 3)
    queue.must_be_empty
  end

  it 'Nested' do
		skip
    process = create NestedJob, input: 4

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    process.processes.must_be_empty
    process.must_have input: 4
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process.processes(NestedJob::Level1).must_be_queued
    process.processes(NestedJob::Level1).processes.must_be_empty
    process.must_have input: 4
    queue.must_enqueued process.processes(NestedJob::Level1)

    execute queue

    process.must_be_waiting
    process.processes(NestedJob::Level1).must_be_waiting
    process.processes(NestedJob::Level1).processes(NestedJob::Level1::Level2).must_be_queued
    process.must_have input: 5
    queue.must_enqueued process.processes(NestedJob::Level1).processes(NestedJob::Level1::Level2)

    execute queue

    process.must_be_completed
    process.processes(NestedJob::Level1).must_be_completed
    process.processes(NestedJob::Level1).processes(NestedJob::Level1::Level2).must_be_completed
    process.must_have input: 5, output: 25
    queue.must_be_empty
  end

  it 'Dependency alias' do
		skip
    process = create DependencyAliasJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    process.processes.must_be_empty
    process.data.must_be_empty
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process.processes(:word_1).must_be_queued
    process.processes(:word_2).must_be_pending
    process.processes(:word_3).must_be_pending
    process.data.must_be_empty
    queue.must_enqueued process.processes(:word_1)

    execute queue

    process.must_be_waiting
    process.processes(:word_1).must_be_completed
    process.processes(:word_2).must_be_queued
    process.processes(:word_3).must_be_pending
    process.must_have text: 'Take'
    queue.must_enqueued process.processes(:word_2)

    execute queue

    process.must_be_waiting
    process.processes(:word_1).must_be_completed
    process.processes(:word_2).must_be_completed
    process.processes(:word_3).must_be_queued
    process.must_have text: 'Take it'
    queue.must_enqueued process.processes(:word_3)

    execute queue

    process.must_be_completed
    process.processes(:word_1).must_be_completed
    process.processes(:word_2).must_be_completed
    process.processes(:word_3).must_be_completed
    process.must_have text: 'Take it easy'
    queue.must_be_empty
  end
  
  it 'Custom queue' do
		skip
    process = create CustomQueueJob, input: 'hello'

    process.must_be_initialized
    
    env.queue(:queue_1).must_be_empty
    env.queue(:queue_2).must_be_empty
    env.queue(:queue_3).must_be_empty

    process.enqueue

    process.must_be_queued
    process.processes.must_be_empty
    process.must_have input: 'hello'
    
    env.queue(:queue_1).must_enqueued process
    env.queue(:queue_2).must_be_empty
    env.queue(:queue_3).must_be_empty

    execute env.queue(:queue_1)

    process.must_be_waiting
    process.processes(CustomQueueJob::Reverse).must_be_queued
    process.must_have input: 'hello'
    
    env.queue(:queue_1).must_be_empty
    env.queue(:queue_2).must_enqueued process.processes(CustomQueueJob::Reverse)
    env.queue(:queue_3).must_be_empty

    execute env.queue(:queue_2)

    process.must_be_completed
    process.processes(CustomQueueJob::Reverse).must_be_completed
    process.must_have input: 'hello', output: 'olleh'
    
    env.queue(:queue_1).must_be_empty
    env.queue(:queue_2).must_be_empty
    env.queue(:queue_3).must_be_empty
  end

  it 'Exception' do
    process = create ExceptionJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_aborted
    process.error.must_be_instance_of Asynchronic::Error
    process.error.message.must_equal 'Error for test'
  end

  it 'Inner exception' do
    process = create InnerExceptionJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process.processes(ExceptionJob).must_be_queued
    queue.must_enqueued process.processes(ExceptionJob)

    execute queue

    process.must_be_aborted
    process.error.must_be_instance_of Asynchronic::Error
    process.error.message.must_equal 'Error caused by ExceptionJob'

    process.processes(ExceptionJob).must_be_aborted
    process.processes(ExceptionJob).error.must_be_instance_of Asynchronic::Error
    process.processes(ExceptionJob).error.message.must_equal 'Error for test'
  end

end