require 'minitest_helper'

describe Asynchronic::DataStore::ScopedStore do

  let(:data_store) { MiniTest::Mock.new }
  let(:scoped_store) { Asynchronic::DataStore::ScopedStore.new data_store, :scope }

  it 'Get' do
    data_store.expect(:[], 1, ['scope|key'])
    scoped_store[:key].must_equal 1
  end

  it 'Set' do
    data_store.expect(:[]=, nil, ['scope|key', 1])
    scoped_store[:key] = 1
  end

  it 'Keys' do
    data_store.expect(:keys, ['scope|a', 'scope|b'])
    scoped_store.keys.must_equal ['a', 'b']
  end

  it 'Delete' do
    data_store.expect(:delete, nil, ['scope|key'])
    scoped_store.delete :key
  end

  it 'Each' do
    data_store.expect(:keys, ['scope|a', 'scope|b'])
    data_store.expect(:[], 1, ['scope|a'])
    data_store.expect(:[], 2, ['scope|b'])

    array = []
    scoped_store.each { |k,v| array << "#{k} => #{v}" }
    array.must_equal ['a => 1', 'b => 2']
  end

  it 'Merge' do
    data_store.expect(:[]=, nil, ['scope|a', 1])
    data_store.expect(:[]=, nil, ['scope|b', 2])
    scoped_store.merge a: 1, b: 2
  end

  it 'Clear' do
    data_store.expect(:keys, ['scope|key'])
    data_store.expect(:delete, nil, ['scope|key'])
    scoped_store.clear
  end

  it 'Scoped' do
    data_store.expect(:[], 1, ['scope|nested|key'])
    nested = scoped_store.scoped :nested
    nested[:key].must_equal 1
  end

  it 'To string' do
    scoped_store.to_s.must_match /#<Asynchronic::DataStore::ScopedStore @data_store=.+ @scope=scope>/
  end

end