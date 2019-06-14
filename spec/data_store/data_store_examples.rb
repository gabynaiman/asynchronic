module DataStoreExamples
  
  it 'Get/Set value' do
    data_store[:key] = 123
    data_store[:key].must_equal 123
  end

  it 'Key not found' do
    data_store[:key].must_be_nil
  end

  it 'Keys' do
    data_store.keys.must_be_empty
    data_store[:key] = 123
    data_store.keys.must_equal ['key']
  end

  it 'Delete' do
    data_store[:key] = 123
    data_store.delete :key
    data_store[:key].must_be_nil
  end

  it 'Delete cascade' do
    data_store[Asynchronic::DataStore::Key[:key_1]] = 1
    data_store[Asynchronic::DataStore::Key[:key_1][:key_1_1]] = 2
    data_store[Asynchronic::DataStore::Key[:key_1][:key_1_2]] = 3
    data_store[Asynchronic::DataStore::Key[:key_2]] = 4
    data_store[Asynchronic::DataStore::Key[:key_2][:key_2_1]] = 5
    data_store[Asynchronic::DataStore::Key[:key_2][:key_2_2]] = 6

    data_store.delete_cascade Asynchronic::DataStore::Key[:key_1]

    data_store.keys.sort.must_equal [
      Asynchronic::DataStore::Key[:key_2], 
      Asynchronic::DataStore::Key[:key_2][:key_2_1], 
      Asynchronic::DataStore::Key[:key_2][:key_2_2]
    ]
  end

  it 'Each' do
    data_store[:a] = 1
    data_store[:b] = 2

    array = []
    data_store.each { |k,v| array << "#{k} => #{v}" }
    array.must_equal_contents ['a => 1', 'b => 2']
  end

  it 'Merge' do
    data_store[:a] =  0
    data_store.merge a: 1, b: 2

    data_store[:a].must_equal 1
    data_store[:b].must_equal 2
  end

  it 'Clear' do
    data_store[:key] = 123
    data_store.clear
    data_store.keys.must_be_empty
  end

  it 'Scoped' do
    data_store['x|y|z'] = 1
    data_store.scoped(:x)['y|z'].must_equal 1
    data_store.scoped(:x).scoped(:y)[:z].must_equal 1
  end

  it 'Read only' do
    data_store[:key] = 1
    data_store.wont_be :readonly?
    data_store.readonly.tap do |ds|
      ds[:key].must_equal 1
      ds.must_be :readonly?
      proc { ds[:key] = 2 }.must_raise RuntimeError
    end
  end

  it 'Lazy' do
    data_store[:key] =  1
    lazy_store = data_store.lazy
    lazy_value = lazy_store[:key]

    data_store.wont_be :lazy?
    lazy_store.must_be :lazy?
    lazy_value.must_equal 1

    data_store[:key] =  2

    lazy_value.must_equal 1
    lazy_value.reload.must_equal 2
  end

  it 'No lazy' do
    data_store[:key] =  1
    lazy_store = data_store.lazy
    no_lazy_store = lazy_store.no_lazy

    data_store.wont_be :lazy?
    lazy_store.must_be :lazy?
    no_lazy_store.wont_be :lazy?

    no_lazy_store[:key].must_equal 1

    data_store[:key] =  2

    no_lazy_store[:key].must_equal 2
  end

  it 'Synchronization' do
    sum = 0
    threads = 1.upto(100).map do |i|
      Thread.new do
        data_store.synchronize('xxx') do
          temp = sum
          sleep 0
          sum = temp + 1
        end
      end
    end
    threads.each(&:join)
      
    sum.must_equal 100
  end
  
end