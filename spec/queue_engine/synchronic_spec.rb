require 'minitest_helper'

describe Asynchronic::QueueEngine::Synchronic do

  before do
    Asynchronic.configure do |config|
      config.queue_engine = Asynchronic::QueueEngine::Synchronic.new
    end
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
  
end