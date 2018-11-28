require 'minitest_helper'

describe Asynchronic, 'Facade' do

  after do
    Asynchronic.environment.data_store.clear
    Asynchronic.environment.queue_engine.clear
  end
  
  it 'Default queue' do
    Asynchronic.default_queue.must_equal :asynchronic_test
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

  it 'Load process' do
    process = Asynchronic.environment.create_process BasicJob
    Asynchronic[process.id].tap do |p|
      p.id.must_equal process.id
      p.type.must_equal process.type
      p.created_at.must_equal process.created_at
    end
  end

  it 'List processes' do
    ids = 3.times.map do 
      process = Asynchronic.environment.create_process SequentialJob
      process.id
    end

    Asynchronic.processes.count.must_equal 3
    3.times { |i| Asynchronic.processes[i].id == ids[i] }
  end

  it 'Enqueue' do
    id = BasicJob.enqueue input: 100
    
    Asynchronic.environment.tap do |env|
      process = env.load_process id
      process.type.must_equal BasicJob
      process.params[:input].must_equal 100
      env.default_queue.must_enqueued process
    end
  end

  it 'Garbage collector' do
    Asynchronic.garbage_collector.must_be_instance_of Asynchronic::GarbageCollector
  end

end