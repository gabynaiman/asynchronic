module LazyValueExamples

  def lazy_value(key)
    Asynchronic::DataStore::LazyValue.new data_store, key
  end

  it 'Get' do
    value = lazy_value :key
    value.must_be_nil
    
    data_store[:key] =  1
    value.must_equal 1
  end

  it 'Reload' do
    value = lazy_value :key

    data_store[:key] =  1
    value.must_equal 1

    data_store[:key] =  2
    value.must_equal 1
    value.reload.must_equal 2
  end

  it 'Transparent proxy' do
    value = lazy_value :key
    data_store[:key] =  1
    value.must_be_instance_of Fixnum
    value.must_equal 1
  end

  it 'Inspect' do
    value = lazy_value :key
    value.inspect.must_match /#<Asynchronic::DataStore::LazyValue @data_store_class=.+ @data_store_connection_args=.+ @key=key>/
  end

end