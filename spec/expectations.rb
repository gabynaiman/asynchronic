module MiniTest::Assertions

  def assert_enqueued(expected_jobs, queue)
    messages = Array(expected_jobs).map { |j| j.parent ? j.parent.local_jobs[j.id] : j.id }
    queue.to_a.must_equal messages, "Jobs #{Array(expected_jobs).map(&:name)}"
  end

  def assert_have_data(expected_hash, job)
    actual_hash = job.local_data.to_hash
    actual_hash.keys.count.must_equal expected_hash.keys.count, "Missing keys\nExpected keys: #{expected_hash.keys}\n  Actual keys: #{actual_hash.keys}"
    expected_hash.each do |k,v|
      job[k].must_equal v, "Key #{k}"
    end
  end

end


Asynchronic::QueueEngine::InMemory::Queue.infect_an_assertion :assert_enqueued, :must_enqueued
Asynchronic::Job.infect_an_assertion :assert_have_data, :must_have_data
