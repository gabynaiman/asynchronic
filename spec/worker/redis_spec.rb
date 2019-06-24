require 'minitest_helper'
require_relative './worker_examples'

describe Asynchronic::Worker, 'Redis' do

  let(:queue_engine) { Asynchronic::QueueEngine::Ost.new }
  let(:data_store) { Asynchronic::DataStore::Redis.new :asynchronic_test}
  let(:notifier) { Asynchronic::Notifier::Broadcaster.new }

  after do
    data_store.clear
    queue_engine.clear
  end

  include WorkerExamples

end