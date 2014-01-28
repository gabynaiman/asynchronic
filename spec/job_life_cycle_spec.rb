require 'minitest_helper'

describe 'Asynchronic::Job - Life cycle' do

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
    job = Factory.single_job context
    job.enqueue input: 1

    job.must_have_data input: 1
    queue.must_enqueued job

    process_queue

    job.must_have_data input: 1, output: 2
    queue.must_be_empty
  end

  it 'Sequential' do
    job = Factory.sequential_job context
    job.enqueue input: 50

    job.must_have_data input: 50
    queue.must_enqueued job

    process_queue

    job.must_have_data input: 50
    queue.must_enqueued job.jobs(:step1)

    process_queue

    job.must_have_data input: 50, partial: 500
    queue.must_enqueued job.jobs(:step2)

    process_queue

    job.must_have_data input: 50, partial: 500, output: 5
    queue.must_be_empty
  end

  it 'Graph' do
    job = Factory.graph_job context
    job.enqueue input: 100

    job.must_have_data input: 100
    queue.must_enqueued job

    process_queue

    job.must_have_data input: 100
    queue.must_enqueued job.jobs(:sum)
    
    process_queue

    job.must_have_data input: 100, sum: 200
    queue.must_enqueued [job.jobs('20%'), job.jobs('10%')]

    2.times { process_queue }

    job.must_have_data input: 100, sum: 200, '10%' => 20, '20%' => 40
    queue.must_enqueued job.jobs(:totals)

    process_queue

    job.must_have_data input: 100, sum: 200, '10%' => 20, '20%' => 40, output: {'10%' => 20, '20%' => 40}
    queue.must_be_empty
  end

  it 'Parallel' do
    job = Factory.parallel_job context
    job.enqueue input: 2, times: 3

    job.must_have_data input: 2, times: 3
    queue.must_enqueued job

    process_queue

    job.must_have_data input: 2, times: 3
    queue.must_enqueued 3.times.map { |i| job.jobs("time_#{i}") }.reverse

    3.times { process_queue }

    hash = Hash[3.times.map { |i| ["time_#{i}", 2 * i] }]
    job.must_have_data hash.merge(input: 2, times: 3)
    queue.must_be_empty
  end

  it 'Exception'

end