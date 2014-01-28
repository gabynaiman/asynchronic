require 'minitest_helper'

describe Asynchronic::Key do

  let(:data_store) { Asynchronic::DataStore::InMemory.new }

  describe 'Single key' do

    let(:key) { Asynchronic::Key.new(:key_1, data_store) }

    it 'To string' do
      key.must_equal 'key_1'
    end

    it 'Get' do
      data_store.set key, 123
      key.get.must_equal 123
    end

    it 'Set' do
      key.set 123
      data_store.get(key).must_equal 123
    end

    it 'Merge' do
      key.merge key_2: 123

      data_store.get(key).must_be_nil
      data_store.get("key_1:key_2").must_equal 123
    end

    it 'To hash' do
      key.set 123
      key[:key_2].set 456

      key.to_hash.must_equal 'key_2' => 456
    end

  end

  describe 'Nested keys' do

    let(:key) { Asynchronic::Key.new(:key_1, data_store)[:nested] }

    it 'To string' do
      key.must_equal 'key_1:nested'
    end

    it 'Get' do
      data_store.set key, 123
      key.get.must_equal 123
    end

    it 'Set' do
      key.set 123
      data_store.get(key).must_equal 123
    end

    it 'Merge' do
      key.merge key_2: 123

      data_store.get(key).must_be_nil
      data_store.get("key_1:nested:key_2").must_equal 123
    end

    it 'To hash' do
      key.set 123
      key[:key_2].set 456
      
      key.to_hash.must_equal 'key_2' => 456
    end

  end
  
end