require 'minitest_helper'

describe Asynchronic::Worker, 'Redis' do

  let(:queue_engine) { Asynchronic::QueueEngine::Ost.new }
  let(:data_store) { Asynchronic::DataStore::Redis.new :asynchronic_test}
  let(:notifier) { Asynchronic::Notifier::Broadcaster.new }

  include WorkerExamples

end