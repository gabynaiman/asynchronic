require 'minitest_helper'

describe Asynchronic::QueueEngine::Synchronic do

  before do
    Asynchronic.configure do |config|
      config.queue_engine = Asynchronic::QueueEngine::Synchronic.new
    end
  end

  after do
    Asynchronic.environment.data_store.clear
  end

  it 'Original job' do
    pid = BasicJob.enqueue input: 1
    process = Asynchronic[pid]
    process.result.must_equal 2
  end

  it 'Stub job' do
    Asynchronic.queue_engine.stub BasicJob do |process|
      process.params[:input] + 19
    end
    
    pid = BasicJob.enqueue input: 1
    process = Asynchronic[pid]
    process.result.must_equal 20
  end

  it 'Graph job' do
    pid = GraphJob.enqueue input: 100
    process = Asynchronic[pid]
    process.must_be_completed
    process.result.must_equal '10%' => 20, '20%' => 40
  end
  
end