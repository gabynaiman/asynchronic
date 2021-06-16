require 'minitest_helper'

describe Asynchronic::DataStore::InMemory do

  let(:data_store) { Asynchronic::DataStore::InMemory.new }

  include DataStoreExamples

  describe 'LazyValue' do
    include LazyValueExamples
  end

end