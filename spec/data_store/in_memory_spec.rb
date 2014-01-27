require 'minitest_helper'

describe Asynchronic::DataStore::InMemory do

  let(:db) { Asynchronic::DataStore::InMemory::DB.new }

  describe Asynchronic::DataStore::InMemory::DB do

    it 'Get/Set value' do
      db.set :test_key, 123
      db.get(:test_key).must_equal 123
      db.keys.must_equal [:test_key]
    end

    it 'Key not found' do
      db.get(:test_key).must_be_nil
    end

    it 'Keys'

    it 'Merge!'

    it 'Clear' do
      db.set :test_key, 123
      db.clear
      db.keys.must_be_empty
    end

  end

  describe Asynchronic::DataStore::InMemory::Key do

    describe 'Single key' do

      let(:key) { Asynchronic::DataStore::InMemory::Key.new db, :test }

      it 'To string' do
        key.to_s.must_equal 'test'
      end

      it 'Get' do
        db.set key.to_s, 123
        key.get.must_equal 123
      end

      it 'Set' do
        key.set 456
        db.get(key.to_s).must_equal 456
      end

    end

    describe 'Nested keys' do

      let(:key) { Asynchronic::DataStore::InMemory::Key.new(db, :test)[:nested] }

      it 'To string' do
        key.to_s.must_equal 'test:nested'
      end

      it 'Get' do
        db.set key.to_s, 123
        key.get.must_equal 123
      end

      it 'Set' do
        key.set 456
        db.get(key.to_s).must_equal 456
      end

    end

  end

end