require 'minitest_helper'

describe Asynchronic::DataStore::Redis do

  let(:data_store) { Asynchronic::DataStore::Redis.new :asynchronic_test }

  include DataStoreExamples

  describe 'LazyValue' do
    include LazyValueExamples
  end

  it 'Safe deserialization' do
    SampleClass = Class.new

    data_store[:class] =  SampleClass
    data_store[:instance] =  SampleClass.new

    Object.send :remove_const, :SampleClass

    data_store[:class].must_be_instance_of String
    data_store[:instance].must_be_instance_of String
  end

end