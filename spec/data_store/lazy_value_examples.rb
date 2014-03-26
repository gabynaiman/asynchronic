module LazyValueExamples

  def lazy_value(key)
    Asynchronic::DataStore::LazyValue.new data_store, key
  end

  it 'Get' do
    value = lazy_value :key
    value.must_be_nil
    
    data_store.set :key, 1
    value.must_equal 1
  end

  it 'Reload' do
    value = lazy_value :key

    data_store.set :key, 1
    value.must_equal 1

    data_store.set :key, 2
    value.must_equal 1
    value.reload.must_equal 2
  end

  it 'Transparent proxy' do
    value = lazy_value :key
    data_store.set :key, 1
    value.must_be_instance_of Fixnum
  end

  it 'Inspect' do
    lazy_value(:key).inspect.must_equal "#<Asynchronic::DataStore::LazyValue data_store=#{data_store.class}, key='key'>"
  end

end