module QueueEngineExamples

  extend Minitest::Spec::DSL

  let(:queue) { engine[:test_queue] }

  let(:listener) { engine.listener }

  after do
    engine.clear
  end

  it 'Engine' do
    engine.queue_names.must_be_empty

    queue = engine[:test_engine]
    queue.must_be_instance_of engine.class.const_get(:Queue)
    engine.queue_names.must_equal [:test_engine]

    engine[:test_engine].must_equal queue

    engine.clear
    engine.queue_names.must_be_empty
  end

  it 'Queue (push/pop)' do
    queue.must_be_empty

    queue.push 'msg_1'
    queue.push 'msg_2'

    queue.size.must_equal 2
    queue.to_a.must_equal %w(msg_1 msg_2)

    queue.pop.must_equal 'msg_1'

    queue.size.must_equal 1
    queue.to_a.must_equal %w(msg_2)
  end

  it 'Listener' do
    Timeout.timeout(5) do
      queue.push 'msg_1'
      queue.push 'msg_2'

      messages = []

      listener.listen(queue) do |msg|
        messages << msg
        listener.stop if queue.empty?
      end

      messages.must_equal %w(msg_1 msg_2)
    end
  end

  it 'Active connections' do
    engine.active_connections.must_equal [Asynchronic.connection_name]
  end

end