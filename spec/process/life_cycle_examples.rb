module LifeCycleExamples

  extend Minitest::Spec::DSL
  
  let(:env) { Asynchronic::Environment.new queue_engine, data_store, notifier }

  let(:queue) { env.default_queue }

  after do
    data_store.clear
    queue_engine.clear
    notifier.unsubscribe_all
  end

  def create(type, params={})
    env.create_process(type, params).tap do |process|
      process.must_be_initialized
    end
  end

  def execute(queue)
    process = env.load_process(queue.pop)

    events = []
    status_changed_id = notifier.subscribe(process.id, :status_changed) { |status| events << status }

    is_finalized = false
    finalized_id = notifier.subscribe(process.id, :finalized) { is_finalized = true }

    process.execute

    process.must_have_connection_name
    process.wont_be :dead?
    
    process.send(:connected?).must_be_true

    env.queue_engine.stub(:active_connections, ->() { raise 'Forced error' }) do
      process.send(:connected?).must_be_true
    end

    with_retries do
      events.last.must_equal process.status
      process.finalized?.must_equal is_finalized
    end

    notifier.unsubscribe status_changed_id
    notifier.unsubscribe finalized_id

    status = process.status
    process.abort_if_dead
    process.status.must_equal status
  end

  def with_retries(&block)
    Timeout.timeout(3) do
      begin
        block.call
      rescue Minitest::Assertion
        sleep 0.001
        retry
      end
    end
  end

  it 'Basic' do
    process = create BasicJob, input: 1

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

  it 'Job with retries' do
    process = create WithRetriesJob

    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_completed
    process.result.must_equal 3
    queue.must_be_empty
  end

  it 'Inheritance of queues in processes. Use default queue' do
    process = create NestedJob, input: 100

    process.queue.must_be_nil

    process.enqueue
    execute queue

    process.processes.first.queue.must_be_nil
    execute queue

    process.processes.first.processes.first.queue.must_be_nil
    execute queue
  end

  it 'Inheritance of queues in processes. Specify queue in params' do
    process = create NestedJob, input: 100, queue: :test_queue

    process.queue.must_equal :test_queue

    process.enqueue
    execute queue_engine[:test_queue]

    process.processes.first.queue.must_equal :test_queue
    execute queue_engine[:test_queue]

    process.processes.first.processes.first.queue.must_equal :test_queue
    execute queue_engine[:test_queue]
  end

  it 'Inheritance of queues in processes. Redefine queue in job class' do
    process = create NestedJobWithDifferentsQueuesJob, input: 100, queue: :test_queue

    process.queue.must_equal :test_queue

    process.enqueue
    execute queue_engine[:test_queue]

    process.processes.first.queue.must_equal :other_queue
    execute queue_engine[:other_queue]

    process.processes.first.processes.first.queue.must_equal :other_queue
    execute queue_engine[:other_queue]
  end

  it 'Data' do
    process = create DataJob, input: 1
  
    process.enqueue
    execute queue

    process.must_be_completed
    process.result.must_be_nil
    process.data.must_equal text: 'Input was 1', value: 1
  end

  it 'Nested job with error in child' do
    process = create NestedJobWithErrorInChildJob

    process.enqueue 

    Timeout.timeout(1) do
      until process.status == :aborted
        execute queue
      end
    end

    process.real_error.must_equal "Error in Child_2_2"
  end

  it 'Nested job with error in parent' do
    process = create NestedJobWithErrorInParentJob

    process.enqueue 

    execute queue
 
    process.real_error.must_equal "Error in parent"
  end

  it 'Abort queued After error' do
    process = create AbortQueuedAfterErrorJob

    process.enqueue 

    execute queue

    process.full_status.must_equal 'AbortQueuedAfterErrorJob'          => :waiting,
                                   'AbortQueuedAfterErrorJob::Child_1' => :queued,
                                   'AbortQueuedAfterErrorJob::Child_2' => :queued,
                                   'AbortQueuedAfterErrorJob::Child_3' => :queued,
                                   'AbortQueuedAfterErrorJob::Child_4' => :queued

    execute queue

    process.full_status.must_equal 'AbortQueuedAfterErrorJob'          => :waiting,
                                   'AbortQueuedAfterErrorJob::Child_1' => :waiting,
                                   'Child_1_1'                         => :queued,
                                   'Child_1_2'                         => :queued,
                                   'AbortQueuedAfterErrorJob::Child_2' => :queued,
                                   'AbortQueuedAfterErrorJob::Child_3' => :queued,
                                   'AbortQueuedAfterErrorJob::Child_4' => :queued

    execute queue

    process.full_status.must_equal 'AbortQueuedAfterErrorJob'          => :waiting,
                                   'AbortQueuedAfterErrorJob::Child_1' => :waiting,
                                   'Child_1_1'                         => :queued,
                                   'Child_1_2'                         => :queued,
                                   'AbortQueuedAfterErrorJob::Child_2' => :completed,
                                   'AbortQueuedAfterErrorJob::Child_3' => :queued,
                                   'AbortQueuedAfterErrorJob::Child_4' => :queued

    execute queue

    process.full_status.must_equal 'AbortQueuedAfterErrorJob'          => :aborted,
                                   'AbortQueuedAfterErrorJob::Child_1' => :waiting,
                                   'Child_1_1'                         => :queued,
                                   'Child_1_2'                         => :queued,
                                   'AbortQueuedAfterErrorJob::Child_2' => :completed,
                                   'AbortQueuedAfterErrorJob::Child_3' => :aborted,
                                   'AbortQueuedAfterErrorJob::Child_4' => :queued

    execute queue

    process.full_status.must_equal 'AbortQueuedAfterErrorJob'          => :aborted,
                                   'AbortQueuedAfterErrorJob::Child_1' => :waiting,
                                   'Child_1_1'                         => :queued,
                                   'Child_1_2'                         => :queued,
                                   'AbortQueuedAfterErrorJob::Child_2' => :completed,
                                   'AbortQueuedAfterErrorJob::Child_3' => :aborted,
                                   'AbortQueuedAfterErrorJob::Child_4' => :aborted

    execute queue

    process.full_status.must_equal 'AbortQueuedAfterErrorJob'          => :aborted,
                                   'AbortQueuedAfterErrorJob::Child_1' => :aborted,
                                   'Child_1_1'                         => :aborted,
                                   'Child_1_2'                         => :queued,
                                   'AbortQueuedAfterErrorJob::Child_2' => :completed,
                                   'AbortQueuedAfterErrorJob::Child_3' => :aborted,
                                   'AbortQueuedAfterErrorJob::Child_4' => :aborted

    execute queue

    process.full_status.must_equal 'AbortQueuedAfterErrorJob'          => :aborted,
                                   'AbortQueuedAfterErrorJob::Child_1' => :aborted,
                                   'Child_1_1'                         => :aborted,
                                   'Child_1_2'                         => :aborted,
                                   'AbortQueuedAfterErrorJob::Child_2' => :completed,
                                   'AbortQueuedAfterErrorJob::Child_3' => :aborted,
                                   'AbortQueuedAfterErrorJob::Child_4' => :aborted

    process.real_error.must_equal 'Forced error'
    process.processes[0].processes[1].error.message.must_equal Asynchronic::Process::AUTOMATIC_ABORTED_ERROR_MESSAGE
  end

  it 'Manual abort' do
    process = create NestedJob, input: 10

    process.enqueue

    execute queue

    process.full_status.must_equal 'NestedJob'         => :waiting, 
                                   'NestedJob::Level1' => :queued

    execute queue

    process.full_status.must_equal 'NestedJob'                 => :waiting, 
                                   'NestedJob::Level1'         => :waiting, 
                                   'NestedJob::Level1::Level2' => :queued

    process.cancel!

    process.real_error.must_equal Asynchronic::Process::CANCELED_ERROR_MESSAGE

    process.full_status.must_equal 'NestedJob'                 => :aborted, 
                                   'NestedJob::Level1'         => :waiting, 
                                   'NestedJob::Level1::Level2' => :queued

    execute queue

    process.full_status.must_equal 'NestedJob'                 => :aborted, 
                                   'NestedJob::Level1'         => :aborted, 
                                   'NestedJob::Level1::Level2' => :aborted
  end

  it 'Remove process' do
    process_1 = create AliasJob
    process_2 = create AliasJob

    process_1.enqueue

    execute queue

    pid_1 = process_1.id
    pid_2 = process_2.id

    data_store.keys.select { |k| k.start_with? pid_1 }.count.must_equal 38
    data_store.keys.select { |k| k.start_with? pid_2 }.count.must_equal 7

    process_1.destroy

    data_store.keys.select { |k| k.start_with? pid_1 }.count.must_equal 0
    data_store.keys.select { |k| k.start_with? pid_2 }.count.must_equal 7
  end

  it 'Garbage collector' do
    process_1 = create AliasJob
    process_1.enqueue
    4.times { execute queue }
    
    process_2 = create AliasJob
    process_2.enqueue
    execute queue

    process_3 = create BasicJob

    pid_1 = process_1.id
    pid_2 = process_2.id
    pid_3 = process_3.id

    process_1.must_be_completed
    process_2.must_be_waiting
    process_3.must_be_pending

    data_store.keys.select { |k| k.start_with? pid_1 }.count.must_equal 53
    data_store.keys.select { |k| k.start_with? pid_2 }.count.must_equal 38
    data_store.keys.select { |k| k.start_with? pid_3 }.count.must_equal 7

    gc = Asynchronic::GarbageCollector.new env, 0.001
    
    gc.add_condition('Finalized', &:finalized?)
    gc.add_condition('Waiting', &:waiting?)
    gc.add_condition('Exception') { raise 'Invalid condition' }

    gc.conditions_names.must_equal ['Finalized', 'Waiting', 'Exception']

    gc.remove_condition 'Waiting'
    
    gc.conditions_names.must_equal ['Finalized', 'Exception']

    Thread.new do
      sleep 0.01
      gc.stop
    end

    Asynchronic::Process.stub_any_instance(:dead?, -> { id == pid_3 }) do
      gc.start
    end

    data_store.keys.select { |k| k.start_with? pid_1 }.count.must_equal 0
    data_store.keys.select { |k| k.start_with? pid_2 }.count.must_equal 38
    data_store.keys.select { |k| k.start_with? pid_3 }.count.must_equal 0
  end

  it 'Before finalize hook when completed' do
    process = create BeforeFinalizeCompletedJob

    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_completed
    process.get(:key).must_equal 10
    queue.must_be_empty
  end

  it 'Before finalize hook when aborted' do
    process = create BeforeFinalizeAbortedJob

    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_aborted
    process.get(:key).must_equal 2
    queue.must_be_empty
  end

  it 'Before finalize raises exception and aborts' do
    process = create BeforeFinalizeRaisesExceptionJob

    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_aborted
    process.real_error.must_equal 'Before finalize exception'
    queue.must_be_empty
  end

  it 'Before finalize raises exception on aborted job' do
    process = create BeforeFinalizeExceptionOnAbortedJob

    queue.must_be_empty

    process.enqueue

    process.must_be_queued
    queue.must_enqueued process

    execute queue

    process.must_be_aborted
    process.real_error.must_equal 'Job error'
    queue.must_be_empty
  end

end