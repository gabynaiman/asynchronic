require 'minitest_helper'
require_relative './data_store_examples'

describe Asynchronic::DataStore::Redis do

  let(:data_store) { Asynchronic::DataStore::Redis.new }

  before do
    data_store.clear
  end

  include DataStoreExamples

end