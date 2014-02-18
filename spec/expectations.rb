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
    process.wont_be :finalized?
    
    process.processes.must_be_empty
    process.data.must_be_empty
    process.error.must_be_nil
    
    process.created_at.must_be_instance_of Time
    process.queued_at.must_be_nil
    process.started_at.must_be_nil
    process.finalized_at.must_be_nil
  end

  def assert_be_pending(process)
    process.must_be :pending?
    process.wont_be :finalized?

    process.created_at.must_be_instance_of Time
    process.queued_at.must_be_nil
    process.started_at.must_be_nil
    process.finalized_at.must_be_nil
  end

  def assert_be_queued(process)
    process.must_be :queued?
    process.wont_be :finalized?

    process.created_at.must_be_instance_of Time
    process.queued_at.must_be_instance_of Time
    process.started_at.must_be_nil
    process.finalized_at.must_be_nil
  end

  def assert_be_waiting(process)
    process.must_be :waiting?
    process.wont_be :finalized?

    process.created_at.must_be_instance_of Time
    process.queued_at.must_be_instance_of Time
    process.started_at.must_be_instance_of Time
    process.finalized_at.must_be_nil
  end

  def assert_be_completed(process)
    process.must_be :completed?
    process.must_be :finalized?

    process.created_at.must_be_instance_of Time
    process.queued_at.must_be_instance_of Time
    process.started_at.must_be_instance_of Time
    process.finalized_at.must_be_instance_of Time
  end

  def assert_be_aborted(process)
    process.must_be :aborted?
    process.must_be :finalized?

    process.created_at.must_be_instance_of Time
    process.queued_at.must_be_instance_of Time
    process.started_at.must_be_instance_of Time
    process.finalized_at.must_be_instance_of Time
  end

end

Asynchronic::QueueEngine::InMemory::Queue.infect_an_assertion :assert_enqueued, :must_enqueued
Asynchronic::QueueEngine::Ost::Queue.infect_an_assertion :assert_enqueued, :must_enqueued
Asynchronic::Process.infect_an_assertion :assert_have, :must_have
Asynchronic::Process.infect_an_assertion :assert_be_initialized, :must_be_initialized, :unary
Asynchronic::Process.infect_an_assertion :assert_be_pending, :must_be_pending, :unary
Asynchronic::Process.infect_an_assertion :assert_be_queued, :must_be_queued, :unary
Asynchronic::Process.infect_an_assertion :assert_be_waiting, :must_be_waiting, :unary
Asynchronic::Process.infect_an_assertion :assert_be_completed, :must_be_completed, :unary
Asynchronic::Process.infect_an_assertion :assert_be_aborted, :must_be_aborted, :unary