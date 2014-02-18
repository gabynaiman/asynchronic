require 'minitest_helper'

describe Asynchronic, 'Facade' do

  before do
    Asynchronic.environment.data_store.clear
    Asynchronic.environment.queue_engine.clear
  end
  
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

  it 'Load process' do
    process = Asynchronic.environment.build_process BasicJob
    Asynchronic[process.pid].tap do |p|
      p.pid.must_equal process.pid
      p.job.must_equal process.job
    end
  end

  it 'List processes' do
    pids = 3.times.map do 
      process = Asynchronic.environment.build_process SequentialJob
      process.pid
    end

    Asynchronic.processes.count.must_equal 3
    Asynchronic.processes.map(&:pid).each { |pid| pids.must_include pid }
  end

  it 'Enqueue' do
    pid = BasicJob.enqueue input: 100
    
    Asynchronic.environment.tap do |env|
      env.default_queue.to_a.must_equal [pid]
      env[pid].must_be_instance_of BasicJob
      env.load_process(pid)[:input].must_equal 100
    end
  end

end