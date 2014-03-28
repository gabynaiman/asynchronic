require 'minitest_helper'

describe Asynchronic::DataStore::Key do

  Key = Asynchronic::DataStore::Key

  it 'Return the namespace' do
    key = Key.new 'foo'
    key.must_equal 'foo'
  end

  it 'Prepend the namespace' do
    key = Key.new 'foo'
    key['bar'].must_equal 'foo|bar'
  end

  it 'Work in more than one level' do
    key_1 = Key.new 'foo'
    key_2 = Key.new key_1['bar']
    key_2['baz'].must_equal 'foo|bar|baz'
  end

  it 'Be chainable' do
    key = Key.new 'foo'
    key['bar']['baz'].must_equal 'foo|bar|baz'
  end

  it 'Accept symbols' do
    key = Key.new :foo
    key[:bar].must_equal 'foo|bar'
  end

  it 'Accept numbers' do
    key = Key.new 'foo'
    key[3].must_equal 'foo|3'
  end

  it 'Split in sections' do
    key = Key.new(:foo)[:bar][:buz]
    key.sections.must_equal %w(foo bar buz)
  end

  it 'Detect nested sections' do
    Key.new(:foo).wont_be :nested?
    Key.new(:foo)[:bar].must_be :nested?
  end

  it 'Remove first sections' do
    key = Key.new(:foo)[:bar][:buz]
    key.remove_first.must_equal 'bar|buz'
    key.remove_first(2).must_equal 'buz'
  end

  it 'Remove last sections' do
    key = Key.new(:foo)[:bar][:buz]
    key.remove_last.must_equal 'foo|bar'
    key.remove_last(2).must_equal 'foo'
  end
  
end