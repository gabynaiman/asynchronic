require 'minitest_helper'
require_relative './queue_engine_examples'

describe Asynchronic::QueueEngine::InMemory do

  let(:engine) { Asynchronic::QueueEngine::InMemory.new }
  let(:listener) { Asynchronic::QueueEngine::InMemory::Listener.new }

  include QueueEngineExamples
  
end