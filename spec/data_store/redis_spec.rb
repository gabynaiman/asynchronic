require 'minitest_helper'
require_relative './data_store_examples'

describe Asynchronic::DataStore::Redis do

  let(:data_store) { Asynchronic::DataStore::Redis.new }

  before do
    Redis.current.flushdb
  end

  include DataStoreExamples

end