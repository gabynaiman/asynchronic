require 'minitest_helper'

describe Asynchronic::Persistent do

  Dummy = Struct.new :string, :hash, :array do
    include Asynchronic::Persistent
  end

  def dummy_attributes
    ['text', {key1: 'value1', key2: 'value2'}, [1,2,3]]
  end

  def assert_dummy(obj)
    obj.string.must_equal 'text'
    obj.hash.must_equal key1: 'value1', key2: 'value2'
    obj.array.must_equal [1,2,3]
  end

  describe 'Instance methods' do

    let(:dummy) { Dummy.new *dummy_attributes }

    it 'Nest instance identifier' do
      dummy.define_singleton_method(:id) { '123456' }
      dummy.nest.must_equal 'Dummy:123456'
    end

    it 'Save' do
      dummy.id.must_equal nil
      dummy.save
      dummy.id.wont_equal nil

      redis.keys.must_include dummy.nest
      
      assert_dummy Marshal.load(redis.get(dummy.nest))
    end

    it 'Delete' do
      dummy.save
      redis.keys.must_include dummy.nest
      
      dummy.delete
      redis.keys.wont_include dummy.nest
    end

    it 'Archive' do
      dummy.save
      redis.keys.must_include dummy.nest
      refute File.exists?(Asynchronic.archiving_file(dummy.id))
      
      dummy.archive
      redis.keys.wont_include dummy.nest
      assert File.exists?(Asynchronic.archiving_file(dummy.id))

      assert_dummy Marshal.load(Base64.decode64(File.read(Asynchronic.archiving_file(dummy.id))))
    end

  end

  describe 'Class methods' do

    it 'Nest class identifier' do
      Dummy.nest.must_equal 'Dummy'
    end

    it 'Create' do
      dummy = Dummy.create *dummy_attributes

      redis.keys.must_include dummy.nest
      assert_dummy Marshal.load(redis.get(dummy.nest))
    end

    it 'Find' do
      dummy = Dummy.create *dummy_attributes

      assert_dummy Dummy.find(dummy.id)
    end

    it 'Find archived' do
      dummy = Dummy.create *dummy_attributes
      dummy.archive

      assert_dummy Dummy.find(dummy.id)
    end

  end

end