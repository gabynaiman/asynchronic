module LifeCycleExamples
  
  let(:context) { Asynchronic::ExecutionContext.new data_store, queue_engine, :test_queue }

  let(:queue) { context.queue(:test_queue) }

  def process_queue
    context.load_process(queue.pop).execute
  end

  it 'Basic' do
    process = context.build_process BasicJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue input: 1

    process.must_be :queued?
    process.must_have input: 1
    queue.must_enqueued process

    process_queue

    process.must_be :completed?
    process.must_have input: 1, output: 2
    queue.must_be_empty
  end

  it 'Sequential' do
    process = context.build_process SequentialJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue input: 50

    process.must_be :queued?
    process.processes.must_be_empty
    process.must_have input: 50
    queue.must_enqueued process

    process_queue

    process.must_be :waiting?
    process.processes(SequentialJob::Step1).must_be :queued?
    process.processes(SequentialJob::Step2).must_be :pending?
    process.must_have input: 50
    queue.must_enqueued process.processes(SequentialJob::Step1)

    process_queue

    process.must_be :waiting?
    process.processes(SequentialJob::Step1).must_be :completed?
    process.processes(SequentialJob::Step2).must_be :queued?
    process.must_have input: 50, partial: 500
    queue.must_enqueued process.processes(SequentialJob::Step2)

    process_queue

    process.must_be :completed?
    process.processes(SequentialJob::Step1).must_be :completed?
    process.processes(SequentialJob::Step2).must_be :completed?
    process.must_have input: 50, partial: 500, output: 5
    queue.must_be_empty
  end

  it 'Graph' do
    process = context.build_process GraphJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue input: 100

    process.must_be :queued?
    process.processes.must_be_empty
    process.must_have input: 100
    queue.must_enqueued process

    process_queue

    process.must_be :waiting?
    process.processes(GraphJob::Sum).must_be :queued?
    process.processes(GraphJob::TenPercent).must_be :pending?
    process.processes(GraphJob::TwentyPercent).must_be :pending?
    process.processes(GraphJob::Total).must_be :pending?
    process.must_have input: 100
    queue.must_enqueued process.processes(GraphJob::Sum)
    
    process_queue

    process.must_be :waiting?
    process.processes(GraphJob::Sum).must_be :completed?
    process.processes(GraphJob::TenPercent).must_be :queued?
    process.processes(GraphJob::TwentyPercent).must_be :queued?
    process.processes(GraphJob::Total).must_be :pending?
    process.must_have input: 100, sum: 200
    queue.must_enqueued [process.processes(GraphJob::TenPercent), process.processes(GraphJob::TwentyPercent)]

    2.times { process_queue }

    process.must_be :waiting?
    process.processes(GraphJob::Sum).must_be :completed?
    process.processes(GraphJob::TenPercent).must_be :completed?
    process.processes(GraphJob::TwentyPercent).must_be :completed?
    process.processes(GraphJob::Total).must_be :queued?
    process.must_have input: 100, sum: 200, '10%' => 20, '20%' => 40
    queue.must_enqueued process.processes(GraphJob::Total)

    process_queue

    process.must_be :completed?
    process.processes(GraphJob::Sum).must_be :completed?
    process.processes(GraphJob::TenPercent).must_be :completed?
    process.processes(GraphJob::TwentyPercent).must_be :completed?
    process.processes(GraphJob::Total).must_be :completed?
    process.must_have input: 100, sum: 200, '10%' => 20, '20%' => 40, output: {'10%' => 20, '20%' => 40}
    queue.must_be_empty
  end

  it 'Parallel' do
    process = context.build_process ParallelJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue input: 10, times: 3

    process.must_be :queued?
    process.processes.must_be_empty
    process.must_have input: 10, times: 3
    queue.must_enqueued process

    process_queue

    process.must_be :waiting?
    process.processes.each { |p| p.must_be :queued? }
    process.must_have input: 10, times: 3
    queue.must_enqueued process.processes

    3.times { process_queue }

    process.must_be :completed?
    process.processes.each { |p| p.must_be :completed? }
    hash = Hash[3.times.map { |i| ["key_#{i}", 10 * i] }]
    process.must_have hash.merge(input: 10, times: 3)
    queue.must_be_empty
  end

  it 'Nested' do
    process = context.build_process NestedJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue input: 4

    process.must_be :queued?
    process.processes.must_be_empty
    process.must_have input: 4
    queue.must_enqueued process

    process_queue

    process.must_be :waiting?
    process.processes(NestedJob::Level1).must_be :queued?
    process.processes(NestedJob::Level1).processes.must_be_empty
    process.must_have input: 4
    queue.must_enqueued process.processes(NestedJob::Level1)

    process_queue

    process.must_be :waiting?
    process.processes(NestedJob::Level1).must_be :waiting?
    process.processes(NestedJob::Level1).processes(NestedJob::Level1::Level2).must_be :queued?
    process.must_have input: 5
    queue.must_enqueued process.processes(NestedJob::Level1).processes(NestedJob::Level1::Level2)

    process_queue

    process.must_be :completed?
    process.processes(NestedJob::Level1).must_be :completed?
    process.processes(NestedJob::Level1).processes(NestedJob::Level1::Level2).must_be :completed?
    process.must_have input: 5, output: 25
    queue.must_be_empty
  end

  it 'Dependency alias' do
    skip 'Not implemented'
  end

  it 'Exception' do
    process = context.build_process ExceptionJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue

    process.must_be :queued?
    queue.must_enqueued process

    process_queue

    process.must_be :aborted?
    process.error.must_be_instance_of Asynchronic::Error
    process.error.message.must_equal 'Error for test'
  end

  it 'Inner exception' do
    process = context.build_process InnerExceptionJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue

    process.must_be :queued?
    queue.must_enqueued process

    process_queue

    process.must_be :waiting?
    process.processes(ExceptionJob).must_be :queued?
    queue.must_enqueued process.processes(ExceptionJob)

    process_queue

    process.must_be :aborted?
    process.error.must_be_instance_of Asynchronic::Error
    process.error.message.must_equal 'Error caused by ExceptionJob'

    process.processes(ExceptionJob).must_be :aborted?
    process.processes(ExceptionJob).error.must_be_instance_of Asynchronic::Error
    process.processes(ExceptionJob).error.message.must_equal 'Error for test'
  end

end