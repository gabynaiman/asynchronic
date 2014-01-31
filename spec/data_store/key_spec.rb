require 'minitest_helper'

describe Asynchronic::DataStore::Key do

  it 'Return the namespace' do
    key = Asynchronic::DataStore::Key.new('foo')
    key.must_equal 'foo'
  end

  it 'Prepend the namespace' do
    key = Asynchronic::DataStore::Key.new('foo')
    key['bar'].must_equal 'foo:bar'
  end

  it 'Work in more than one level' do
    key_1 = Asynchronic::DataStore::Key.new('foo')
    key_2 = Asynchronic::DataStore::Key.new(key_1['bar'])
    key_2['baz'].must_equal 'foo:bar:baz'
  end

  it 'Be chainable' do
    key = Asynchronic::DataStore::Key.new('foo')
    key['bar']['baz'].must_equal 'foo:bar:baz'
  end

  it 'Accept symbols' do
    key = Asynchronic::DataStore::Key.new(:foo)
    key[:bar].must_equal 'foo:bar'
  end

  it 'Accept numbers' do
    key = Asynchronic::DataStore::Key.new('foo')
    key[3].must_equal 'foo:3'
  end
  
end