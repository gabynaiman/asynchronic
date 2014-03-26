require 'minitest_helper'

describe Asynchronic::DataStore::ScopedStore do

  class FakeStore < BasicObject
    instance_methods.reject { |m| m == :__send__ }.
                     each   { |m| undef_method m }

    def method_missing(method, *args)
      ::Kernel.puts method
    end
  end

  let(:data_store) { MiniTest::Mock.new }
  let(:scoped_store) { Asynchronic::DataStore::ScopedStore.new data_store, :scope }

  it 'Get' do
    data_store.expect(:[], nil, ['scope|key'])
    scoped_store[:key].must_be_nil
  end

  it 'Set' do
    data_store.expect(:[]=, nil, ['scope|key', 1])
    scoped_store[:key] = 1
  end

  it 'All keys' do
    data_store.expect(:keys, nil, ['scope'])
    scoped_store.keys
  end

  it 'Filtered keys' do
    data_store.expect(:keys, nil, ['scope|key'])
    scoped_store.keys :key
  end

  it 'Clear all' do
    data_store.expect(:clear, nil, ['scope'])
    scoped_store.clear
  end

  it 'Filtered clear' do
    data_store.expect(:clear, nil, ['scope|key'])
    scoped_store.clear :key
  end

  it 'Read only' do
    proc { scoped_store.readonly[:key] = 1 }.must_raise RuntimeError
  end

  it 'Merge' do
    data_store.expect(:[]=, nil, ['scope|key|a', 1])
    data_store.expect(:[]=, nil, ['scope|key|b', 2])
    scoped_store.merge :key, a: 1, b: 2
  end

  it 'To Hash' do
    data_store.expect(:keys, [], ['scope|key|'])
    scoped_store.to_hash :key
  end

end