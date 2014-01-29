module MiniTest::Assertions

  def assert_enqueued(expected_jobs, queue)
    messages = Array(expected_jobs).map { |j| j.local_context.to_s }
    queue.to_a.must_equal messages, "Jobs #{Array(expected_jobs).map(&:name)}"
  end

  def assert_have(expected_hash, job)
    job.data.keys.count.must_equal expected_hash.keys.count, "Missing keys\nExpected keys: #{expected_hash.keys}\n  Actual keys: #{job.data.keys}"
    expected_hash.each do |k,v|
      job[k].must_equal v, "Key #{k}"
    end
  end

  def assert_be_initialized(job)
    job.must_be :pending?
    job.jobs.must_be_empty
    job.data.must_be_empty
    job.error.must_be_nil
  end

end

Asynchronic::QueueEngine::InMemory::Queue.infect_an_assertion :assert_enqueued, :must_enqueued
Asynchronic::Job.infect_an_assertion :assert_have, :must_have
Asynchronic::Job.infect_an_assertion :assert_be_initialized, :must_be_initialized, :unary