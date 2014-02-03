require 'minitest_helper'
require_relative './data_store_examples'

describe Asynchronic::DataStore::InMemory do

  let(:data_store) { Asynchronic::DataStore::InMemory.new }

  include DataStoreExamples

end