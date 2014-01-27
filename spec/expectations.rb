module MiniTest::Assertions

  def assert_enqueued(message, queue)
    queue.to_a.must_include message
  end

end


Asynchronic::QueueEngine::InMemory::Queue.infect_an_assertion :assert_enqueued, :must_enqueued
