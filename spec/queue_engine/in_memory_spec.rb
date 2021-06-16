require 'minitest_helper'

describe Asynchronic::QueueEngine::InMemory do

  let(:engine) { Asynchronic::QueueEngine::InMemory.new }
  let(:listener) { Asynchronic::QueueEngine::InMemory::Listener.new }

  include QueueEngineExamples

end