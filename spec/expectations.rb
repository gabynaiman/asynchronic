module MiniTest::Assertions

  def assert_enqueued(expected_processes, queue)
    messages = Array(expected_processes).map { |p| p.job.lookup.id }
    queue.to_a.sort.must_equal messages.sort, "Jobs #{Array(expected_processes).map{ |p| p.job.class }}"
  end

  def assert_have(expected_hash, process)
    process.data.keys.count.must_equal expected_hash.keys.count, "Missing keys\nExpected keys: #{expected_hash.keys}\n  Actual keys: #{process.data.keys}"
    expected_hash.each do |k,v|
      process[k].must_equal v, "Key #{k}"
    end
  end

  def assert_be_initialized(process)
    process.must_be :pending?
    process.processes.must_be_empty
    process.data.must_be_empty
    process.error.must_be_nil
  end

end

Asynchronic::QueueEngine::InMemory::Queue.infect_an_assertion :assert_enqueued, :must_enqueued
Asynchronic::QueueEngine::Ost::Queue.infect_an_assertion :assert_enqueued, :must_enqueued
Asynchronic::Process.infect_an_assertion :assert_have, :must_have
Asynchronic::Process.infect_an_assertion :assert_be_initialized, :must_be_initialized, :unary