require 'minitest_helper'

describe Asynchronic::DataStore::InMemory do

  let(:data_store) { Asynchronic::DataStore::InMemory.new }

  it 'Get/Set value' do
    data_store.set 'test_key', 123
    data_store.get('test_key').must_equal 123
  end

  it 'Key not found' do
    data_store.get('test_key').must_be_nil
  end

  it 'Keys' do
    data_store.keys.must_be_empty
    data_store.set 'test_key', 123
    data_store.keys.must_equal ['test_key']
  end

  it 'Nested keys' do
    data_store.set 'a', 0
    data_store.set 'a:1', 1
    data_store.set 'a:2', 2
    data_store.set 'b:3', 3

    data_store.keys('a').must_equal %w(a a:1 a:2)
    data_store.keys('a:').must_equal %w(a:1 a:2)
  end

  it 'Clear' do
    data_store.set 'test_key', 123
    data_store.clear
    data_store.keys.must_be_empty
  end

  it 'Nested clear' do
    data_store.set 'a', 0
    data_store.set 'a:1', 1
    data_store.set 'a:2', 2
    data_store.set 'b:3', 3

    data_store.clear 'a:'

    data_store.keys.must_equal %w(a b:3)
  end

end