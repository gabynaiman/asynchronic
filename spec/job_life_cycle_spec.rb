require 'minitest_helper'

describe Asynchronic::Job, 'Life cycle' do

  let(:context) do 
    queue_engine = Asynchronic::QueueEngine::InMemory.new
    data_store = Asynchronic::DataStore::InMemory.new
    Asynchronic::ExecutionContext.new data_store, queue_engine, :test_queue
  end

  let(:queue) { context.queue(:test_queue) }

  def process_queue
    context.load_job(queue.pop).execute
  end

  it 'Single' do
    job = Factory.simple_job context

    job.must_be_initialized
    queue.must_be_empty

    job.enqueue input: 1

    job.must_be :queued?
    job.must_have input: 1
    queue.must_enqueued job

    process_queue

    job.must_be :completed?
    job.must_have input: 1, output: 2
    queue.must_be_empty
  end

  it 'Sequential' do
    job = Factory.sequential_job context

    job.must_be_initialized
    queue.must_be_empty

    job.enqueue input: 50

    job.must_be :queued?
    job.jobs.must_be_empty
    job.must_have input: 50
    queue.must_enqueued job

    process_queue

    job.must_be :waiting?
    job.jobs(:step1).must_be :queued?
    job.jobs(:step2).must_be :pending?
    job.must_have input: 50
    queue.must_enqueued job.jobs(:step1)

    process_queue

    job.must_be :waiting?
    job.jobs(:step1).must_be :completed?
    job.jobs(:step2).must_be :queued?
    job.must_have input: 50, partial: 500
    queue.must_enqueued job.jobs(:step2)

    process_queue

    job.must_be :completed?
    job.jobs(:step1).must_be :completed?
    job.jobs(:step2).must_be :completed?
    job.must_have input: 50, partial: 500, output: 5
    queue.must_be_empty
  end

  it 'Graph' do
    job = Factory.graph_job context

    job.must_be_initialized
    queue.must_be_empty

    job.enqueue input: 100

    job.must_be :queued?
    job.jobs.must_be_empty
    job.must_have input: 100
    queue.must_enqueued job

    process_queue

    job.must_be :waiting?
    job.jobs(:sum).must_be :queued?
    job.jobs('10%').must_be :pending?
    job.jobs('20%').must_be :pending?
    job.jobs(:totals).must_be :pending?
    job.must_have input: 100
    queue.must_enqueued job.jobs(:sum)
    
    process_queue

    job.must_be :waiting?
    job.jobs(:sum).must_be :completed?
    job.jobs('10%').must_be :queued?
    job.jobs('20%').must_be :queued?
    job.jobs(:totals).must_be :pending?
    job.must_have input: 100, sum: 200
    queue.must_enqueued [job.jobs('10%'), job.jobs('20%')]

    2.times { process_queue }

    job.must_be :waiting?
    job.jobs(:sum).must_be :completed?
    job.jobs('10%').must_be :completed?
    job.jobs('20%').must_be :completed?
    job.jobs(:totals).must_be :queued?
    job.must_have input: 100, sum: 200, '10%' => 20, '20%' => 40
    queue.must_enqueued job.jobs(:totals)

    process_queue

    job.must_be :completed?
    job.jobs(:sum).must_be :completed?
    job.jobs('10%').must_be :completed?
    job.jobs('20%').must_be :completed?
    job.jobs(:totals).must_be :completed?
    job.must_have input: 100, sum: 200, '10%' => 20, '20%' => 40, output: {'10%' => 20, '20%' => 40}
    queue.must_be_empty
  end

  it 'Parallel' do
    job = Factory.parallel_job context

    job.must_be_initialized
    queue.must_be_empty

    job.enqueue input: 10, times: 3

    job.must_be :queued?
    job.jobs.must_be_empty
    job.must_have input: 10, times: 3
    queue.must_enqueued job

    process_queue

    job.must_be :waiting?
    3.times { |i| job.jobs("job_#{i}").must_be :queued? }
    job.must_have input: 10, times: 3
    queue.must_enqueued 3.times.map { |i| job.jobs("job_#{i}") }

    3.times { process_queue }

    job.must_be :completed?
    3.times { |i| job.jobs("job_#{i}").must_be :completed? }
    hash = Hash[3.times.map { |i| ["key_#{i}", 10 * i] }]
    job.must_have hash.merge(input: 10, times: 3)
    queue.must_be_empty
  end

  it 'Nested' do
    job = Factory.nested_job context

    job.must_be_initialized
    queue.must_be_empty

    job.enqueue input: 4

    job.must_be :queued?
    job.jobs.must_be_empty
    job.must_have input: 4
    queue.must_enqueued job

    process_queue

    job.must_be :waiting?
    job.jobs(:level_1).must_be :queued?
    job.jobs(:level_1).jobs.must_be_empty
    job.must_have input: 4
    queue.must_enqueued job.jobs(:level_1)

    process_queue

    job.must_be :waiting?
    job.jobs(:level_1).must_be :waiting?
    job.jobs(:level_1).jobs(:level_2).must_be :queued?
    job.must_have input: 5
    queue.must_enqueued job.jobs(:level_1).jobs(:level_2)

    process_queue

    job.must_be :completed?
    job.jobs(:level_1).must_be :completed?
    job.jobs(:level_1).jobs(:level_2).must_be :completed?
    job.must_have input: 5, output: 25
    queue.must_be_empty
  end

  it 'Exception' do
    job = Factory.exception_job context

    job.must_be_initialized
    queue.must_be_empty

    job.enqueue

    job.must_be :queued?
    queue.must_enqueued job

    process_queue

    job.must_be :aborted?
    job.error.must_be_instance_of Asynchronic::Error
    job.error.message.must_equal 'Error for test'
  end

  it 'Inner exception' do
    job = Factory.inner_exception_job context

    job.must_be_initialized
    queue.must_be_empty

    job.enqueue

    job.must_be :queued?
    queue.must_enqueued job

    process_queue

    job.must_be :waiting?
    job.jobs(:raise_exception).must_be :queued?
    queue.must_enqueued job.jobs(:raise_exception)

    process_queue

    job.must_be :aborted?
    job.error.must_be_instance_of Asynchronic::Error
    job.error.message.must_equal 'Error caused by raise_exception'

    job.jobs(:raise_exception).must_be :aborted?
    job.jobs(:raise_exception).error.must_be_instance_of Asynchronic::Error
    job.jobs(:raise_exception).error.message.must_equal 'Inner error for test'
  end

end