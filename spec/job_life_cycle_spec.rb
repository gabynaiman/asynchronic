require 'minitest_helper'

describe 'Asynchronic::Job - Life cycle' do

  let(:queue) { Asynchronic::QueueEngine::InMemory::Queue.new }
  let(:data_store) { Asynchronic::DataStore::InMemory::DB.new }

  def process(queue)
    data_store[queue.pop].execute
  end
  
  it 'Single' do
    job = Factory.single_job data_store, input: 1
    job.enqueue queue

    job[:input].must_equal 1
    job[:output].must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued job.id

    process queue

    job[:input].must_equal 1
    job[:output].must_equal 2

    queue.must_be_empty
  end

  it 'Sequential' do
    skip
    job = Factory.sequential_job data_store, input: 50
    job.enqueue

    job[:input].must_equal 50
    job[:partial].must_be_nil
    job[:output].must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued job[:step1]

    process queue

    job[:input].must_equal 50
    job[:partial].must_equal 500
    job[:output].must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued job[:step2]

    process queue

    job[:input].must_equal 50
    job[:partial].must_equal 500
    job[:output].must_equal 5

    queue.must_be_empty
  end

  it 'Graph' do
    skip
    job = Factory.graph_job data_store, input: 100
    job.enqueue

    job[:input].must_equal 100
    job[:sum].must_be_nil
    job['10%'].must_be_nil
    job['20%'].must_be_nil
    job[:output].must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued job.jobs[:sum]
    
    process queue

    job[:input].must_equal 100
    job[:sum].must_equal 200
    job['10%'].must_be_nil
    job['20%'].must_be_nil
    job[:output].must_be_nil
    
    queue.size.must_equal 2
    queue.must_enqueued job.jobs['10%']
    queue.must_enqueued job.jobs['20%']

    process queue

    job[:input].must_equal 100
    job[:sum].must_equal 200
    job['10%'].must_equal 20
    job['20%'].must_equal 40
    job[:output].must_be_nil

    queue.size.must_equal 1
    queue.must_enqueued job.jobs[:totals]

    process queue

    job[:input].must_equal 100
    job[:sum].must_equal 200
    job['10%'].must_equal 20
    job['20%'].must_equal 40
    job[:output].must_equal '10%' => 20, '20%' => 40

    queue.must_be_empty
  end

  it 'Parallel' do
    skip
    job = Factory.parallel_job data_store, input: 2, times: 3
    job.enqueue

    job[:input].must_equal 2
    job[:times].must_equal 3
    3.times { |i| job["time_#{i}"].must_be_nil }

    queue.size.must_equal 3
    3.times { |i| queue.must_enqueued job.jobs["time_#{i}"] }

    process queue

    job[:input].must_equal 2
    job[:times].must_equal 3
    3.times { |i| job["time_#{i}"].must_equal 2 * i }

    queue.must_be_empty
  end

end