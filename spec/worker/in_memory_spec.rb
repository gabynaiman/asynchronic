require 'minitest_helper'

describe Asynchronic::Worker, 'InMemory' do

  let(:queue_engine) { Asynchronic::QueueEngine::InMemory.new }
  let(:data_store) { Asynchronic::DataStore::InMemory.new }
  let(:notifier) { Asynchronic::Notifier::InMemory.new }

  include WorkerExamples

end