require 'minitest_helper'

describe Asynchronic::QueueEngine::InMemory do

  let(:engine) { Asynchronic::QueueEngine::InMemory.new }

  include QueueEngineExamples

end