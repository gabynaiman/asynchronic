require 'minitest_helper'
require_relative './life_cycle_examples.rb'

describe Asynchronic::Job, 'Life cycle (InMemory)' do

  let(:queue_engine) { Asynchronic::QueueEngine::InMemory.new }
  let(:data_store) { Asynchronic::DataStore::InMemory.new }

  include LifeCycleExamples

end