require 'minitest_helper'

describe Asynchronic::QueueEngine::Ost do

  let(:engine) { Asynchronic::QueueEngine::Ost.new }
  let(:listener) { Asynchronic::QueueEngine::Ost::Listener.new }

  include QueueEngineExamples

  it 'Engine and queues use same redis connection' do
    engine.redis.must_equal queue.redis
  end

end