require 'minitest_helper'

describe Asynchronic, 'Facade' do
  
  it 'Default queue' do
    Asynchronic.default_queue.must_equal :asynchronic
  end

  it 'Default queue_engine' do
    Asynchronic.queue_engine.must_be_instance_of Asynchronic::QueueEngine::InMemory
  end

  it 'Default data store' do
    Asynchronic.data_store.must_be_instance_of Asynchronic::DataStore::InMemory
  end

  it 'Default logger' do
    Asynchronic.logger.must_be_instance_of Logger
  end

  it 'Environment' do
    Asynchronic.environment.tap do |env|
      env.queue_engine.must_equal Asynchronic.queue_engine
      env.data_store.must_equal Asynchronic.data_store
    end
  end

  it 'Enqueue' do
    job_key = Asynchronic.enqueue BasicJob, input: 100
    env = Asynchronic.environment

    env.default_queue.to_a.must_equal [job_key]
    env[job_key].must_be_instance_of BasicJob
    env.load_process(job_key)[:input].must_equal 100
  end

end