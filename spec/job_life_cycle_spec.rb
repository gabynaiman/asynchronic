require 'minitest_helper'

describe 'Asynchronic::Job - Life cycle' do

  let(:queue_engine) { Asynchronic::QueueEngine::InMemory.new }
  let(:queue_name) { :test_queue }
  let(:queue) { queue_engine[queue_name] }

  let(:data_store) { Asynchronic::DataStore::InMemory.new }
  
  let(:context) { Asynchronic::ExecutionContext.new queue_engine, data_store }

  def get(job, key)
    context[job.id][key].get
  end

  def enqueue(job, data={})
    context.enqueue job, queue_name, data
  end
  
  def process_queue
    job_id = context.queue(queue_name).pop
    data = context[job_id].to_hash.with_indiferent_access
    context[job_id].get.execute data
    context[job_id].merge data
  end

  it 'Single' do
    job = Factory.single_job 
    enqueue job, input: 1

    get(job, :input).must_equal 1
    get(job, :output).must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued job.id

    process_queue

    get(job, :input).must_equal 1
    get(job, :output).must_equal 2

    queue.must_be_empty
  end

  it 'Sequential' do
    skip
    job = Factory.sequential_job
    enqueue job, input: 50

    get(job, :input).must_equal 50
    get(job, :partial).must_be_nil
    get(job, :output).must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued context[job.id][:step1]

    process_queue

    get(job, :input).must_equal 50
    get(job, :partial).must_equal 500
    get(job, :output).must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued context[job.id][:step2]

    process_queue

    get(job, :input).must_equal 50
    get(job, :partial).must_equal 500
    get(job, :output).must_equal 5

    queue.must_be_empty
  end

  it 'Graph' do
    skip
    job = Factory.graph_job
    enqueue job, input: 100

    get(job, :input).must_equal 100
    get(job, :sum).must_be_nil
    get(job, '10%').must_be_nil
    get(job, '20%').must_be_nil
    get(job, :output).must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued job.jobs[:sum]
    
    process_queue

    get(job, :input).must_equal 100
    get(job, :sum).must_equal 200
    get(job, '10%').must_be_nil
    get(job, '20%').must_be_nil
    get(job, :output).must_be_nil
    
    queue.size.must_equal 2
    queue.must_enqueued job.jobs['10%']
    queue.must_enqueued job.jobs['20%']

    process_queue

    get(job, :input).must_equal 100
    get(job, :sum).must_equal 200
    get(job, '10%').must_equal 20
    get(job, '20%').must_equal 40
    get(job, :output).must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued job.jobs[:totals]

    process_queue

    get(job, :input).must_equal 100
    get(job, :sum).must_equal 200
    get(job, '10%').must_equal 20
    get(job, '20%').must_equal 40
    get(job, :output).must_equal '10%' => 20, '20%' => 40

    queue.must_be_empty
  end

  it 'Parallel' do
    skip
    job = Factory.parallel_job
    enqueue job, input: 2, times: 3

    get(job, :input).must_equal 2
    get(job, :times).must_equal 3
    3.times { |i| get(job, "time_#{i}").must_be_nil }

    queue.size.must_equal 3
    3.times { |i| queue.must_enqueued job.jobs["time_#{i}"] }

    process_queue

    get(job, :input).must_equal 2
    get(job, :times).must_equal 3
    3.times { |i| get(job, "time_#{i}").must_equal 2 * i }

    queue.must_be_empty
  end

end