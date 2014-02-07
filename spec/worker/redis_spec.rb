require 'minitest_helper'
require_relative './worker_examples'

describe Asynchronic::Worker, '(Redis)' do

  let(:queue_engine) { Asynchronic::QueueEngine::Ost.new }
  let(:data_store) { Asynchronic::DataStore::Redis.new }

  before do
    Redis.current.flushdb
  end

  include WorkerExamples

end