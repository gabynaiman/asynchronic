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
    process[SequentialJob::Step1].must_be_queued
    process[SequentialJob::Step1].must_have_params input: 50
    process[SequentialJob::Step2].must_be_pending
    process[SequentialJob::Step2].must_have_params input: 50
    queue.must_enqueued process[SequentialJob::Step1]

    execute queue

    process.must_be_waiting
    process[SequentialJob::Step1].must_be_completed
    process[SequentialJob::Step1].result.must_equal 500
    process[SequentialJob::Step2].must_be_queued
    queue.must_enqueued process[SequentialJob::Step2]

    execute queue

    process.must_be_completed
    process.result.must_be_nil
    process[SequentialJob::Step2].must_be_completed
    process[SequentialJob::Step2].result.must_equal 5
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
    process[GraphJob::Sum].must_be_queued
    process[GraphJob::Sum].must_have_params input: 100
    process[GraphJob::TenPercent].must_be_pending
    process[GraphJob::TenPercent].must_have_params input: nil
    process[GraphJob::TwentyPercent].must_be_pending
    process[GraphJob::TwentyPercent].must_have_params input: nil
    process[GraphJob::Total].must_be_pending
    process[GraphJob::Total].must_have_params '10%' => nil, '20%' => nil
    queue.must_enqueued process[GraphJob::Sum]
    
    execute queue

    process.must_be_waiting
    process[GraphJob::Sum].must_be_completed
    process[GraphJob::Sum].result.must_equal 200
    process[GraphJob::TenPercent].must_be_queued
    process[GraphJob::TenPercent].must_have_params input: 200
    process[GraphJob::TwentyPercent].must_be_queued
    process[GraphJob::TwentyPercent].must_have_params input: 200
    process[GraphJob::Total].must_be_pending
    queue.must_enqueued [process[GraphJob::TenPercent], process[GraphJob::TwentyPercent]]

    2.times { execute queue }

    process.must_be_waiting
    process[GraphJob::TenPercent].must_be_completed
    process[GraphJob::TenPercent].result.must_equal 20
    process[GraphJob::TwentyPercent].must_be_completed
    process[GraphJob::TwentyPercent].result.must_equal 40
    process[GraphJob::Total].must_be_queued
    queue.must_enqueued process[GraphJob::Total]

    execute queue

    process.must_be_completed
    process.result.must_equal '10%' => 20, '20%' => 40
    process[GraphJob::Total].must_be_completed
    process[GraphJob::Total].result.must_equal '10%' => 20, '20%' => 40
    queue.must_be_empty
  end

  it 'Parallel' do
    process = create ParallelJob, input: 10, times: 3

    process.must_be_initialized
    process.must_have_params input: 10, times: 3
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    process.processes.must_be_empty
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process.processes.count.must_equal 3
    process.processes.each_with_index do |p,i|
      p.must_be_queued
      p.must_have_params input: 10, index: i
    end
    queue.must_enqueued process.processes

    3.times { execute queue }

    process.must_be_completed
    process.result.must_equal 3
    process.processes.each_with_index do |p,i|
      p.must_be_completed
      p.result.must_equal 10 * i
    end
    queue.must_be_empty
  end

  it 'Nested' do
    process = create NestedJob, input: 4

    process.must_be_initialized
    process.must_have_params input: 4
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    process.processes.must_be_empty
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process[NestedJob::Level1].must_be_queued
    process[NestedJob::Level1].must_have_params input: 4
    process[NestedJob::Level1].processes.must_be_empty
    queue.must_enqueued process[NestedJob::Level1]

    execute queue

    process.must_be_waiting
    process[NestedJob::Level1].must_be_waiting
    process[NestedJob::Level1][NestedJob::Level1::Level2].must_be_queued
    process[NestedJob::Level1][NestedJob::Level1::Level2].must_have_params input: 5
    queue.must_enqueued process[NestedJob::Level1][NestedJob::Level1::Level2]

    execute queue

    process.must_be_completed
    process.result.must_equal 25
    process[NestedJob::Level1].must_be_completed
    process[NestedJob::Level1].result.must_equal 25
    process[NestedJob::Level1][NestedJob::Level1::Level2].must_be_completed
    process[NestedJob::Level1][NestedJob::Level1::Level2].result.must_equal 25
    queue.must_be_empty
  end

  it 'Alias' do
    process = create AliasJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    process.processes.must_be_empty
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process[:word_1].must_be_queued
    process[:word_1].must_have_params text: 'Take'
    process[:word_2].must_be_pending
    process[:word_2].must_have_params text: 'it', prefix: nil
    process[:word_3].must_be_pending
    process[:word_3].must_have_params text: 'easy', prefix: nil
    queue.must_enqueued process[:word_1]

    execute queue

    process.must_be_waiting
    process[:word_1].must_be_completed
    process[:word_1].result.must_equal 'Take'
    process[:word_2].must_be_queued
    process[:word_2].must_have_params text: 'it', prefix: 'Take'
    process[:word_3].must_be_pending
    queue.must_enqueued process[:word_2]

    execute queue

    process.must_be_waiting
    process[:word_1].must_be_completed
    process[:word_2].must_be_completed
    process[:word_2].result.must_equal 'Take it'
    process[:word_3].must_be_queued
    process[:word_3].must_have_params text: 'easy', prefix: 'Take it'
    queue.must_enqueued process[:word_3]

    execute queue

    process.must_be_completed
    process.result.must_equal 'Take it easy'
    process[:word_1].must_be_completed
    process[:word_2].must_be_completed
    process[:word_3].must_be_completed
    process[:word_3].result.must_equal 'Take it easy'
    queue.must_be_empty
  end
  
  it 'Custom queue' do
    process = create CustomQueueJob, input: 'hello'

    process.must_be_initialized
    process.must_have_params input: 'hello'

    env.queue(:queue_1).must_be_empty
    env.queue(:queue_2).must_be_empty
    env.queue(:queue_3).must_be_empty

    process.enqueue

    process.must_be_queued
    process.processes.must_be_empty
    
    env.queue(:queue_1).must_enqueued process
    env.queue(:queue_2).must_be_empty
    env.queue(:queue_3).must_be_empty

    execute env.queue(:queue_1)

    process.must_be_waiting
    process[CustomQueueJob::Reverse].must_be_queued
    process[CustomQueueJob::Reverse].must_have_params input: 'hello'
    
    env.queue(:queue_1).must_be_empty
    env.queue(:queue_2).must_enqueued process[CustomQueueJob::Reverse]
    env.queue(:queue_3).must_be_empty

    execute env.queue(:queue_2)

    process.must_be_completed
    process.result.must_equal 'olleh'
    process[CustomQueueJob::Reverse].must_be_completed
    process[CustomQueueJob::Reverse].result.must_equal 'olleh'
    
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
    process[ExceptionJob].must_be_queued
    queue.must_enqueued process[ExceptionJob]

    execute queue

    process.must_be_aborted
    process.error.must_be_instance_of Asynchronic::Error
    process.error.message.must_equal 'Error caused by ExceptionJob'

    process[ExceptionJob].must_be_aborted
    process[ExceptionJob].error.must_be_instance_of Asynchronic::Error
    process[ExceptionJob].error.message.must_equal 'Error for test'
  end

  it 'Forward reference' do
    process = create ForwardReferenceJob

    process.must_be_initialized
    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_waiting
    process[ForwardReferenceJob::BuildReferenceJob].must_be_queued
    process[ForwardReferenceJob::SendReferenceJob].must_be_pending
    queue.must_enqueued process[ForwardReferenceJob::BuildReferenceJob]

    execute queue

    process.must_be_waiting
    process[ForwardReferenceJob::BuildReferenceJob].must_be_completed
    process[ForwardReferenceJob::SendReferenceJob].must_be_queued
    queue.must_enqueued process[ForwardReferenceJob::SendReferenceJob]

    execute queue

    process.must_be_waiting
    process[ForwardReferenceJob::BuildReferenceJob].must_be_completed
    process[ForwardReferenceJob::SendReferenceJob].must_be_waiting
    process[ForwardReferenceJob::SendReferenceJob][ForwardReferenceJob::UseReferenceJob].must_be_queued
    queue.must_enqueued process[ForwardReferenceJob::SendReferenceJob][ForwardReferenceJob::UseReferenceJob]

    execute queue

    process.must_be_completed
    process.result.must_equal 2
    process[ForwardReferenceJob::BuildReferenceJob].must_be_completed
    process[ForwardReferenceJob::SendReferenceJob].must_be_completed
    process[ForwardReferenceJob::SendReferenceJob][ForwardReferenceJob::UseReferenceJob].must_be_completed
    queue.must_be_empty
  end

end