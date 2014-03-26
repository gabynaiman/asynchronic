require 'minitest_helper'
require_relative './data_store_examples'
require_relative './lazy_value_examples'

describe Asynchronic::DataStore::Redis do

  let(:data_store) { Asynchronic::DataStore::Redis.new }

  before do
    data_store.clear
  end

  include DataStoreExamples

  it 'Safe deserialization' do
    SampleClass = Class.new

    data_store.set :class, SampleClass
    data_store.set :instance, SampleClass.new

    Object.send :remove_const, :SampleClass

    data_store.get(:class).must_be_instance_of String
    data_store.get(:instance).must_be_instance_of String
  end

  describe 'LazyValue' do
    include LazyValueExamples
  end

end