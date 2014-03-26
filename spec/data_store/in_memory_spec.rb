require 'minitest_helper'
require_relative './data_store_examples'
require_relative './lazy_value_examples'

describe Asynchronic::DataStore::InMemory do

  let(:data_store) { Asynchronic::DataStore::InMemory.new }

  include DataStoreExamples

  describe 'LazyValue' do
    include LazyValueExamples
  end

end