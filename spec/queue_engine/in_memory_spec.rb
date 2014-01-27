require 'minitest_helper'

describe Asynchronic::QueueEngine::InMemory do

  let(:container) { Asynchronic::QueueEngine::InMemory::Container.new }
  let(:queue) { container[:test_queue]}
  let(:listener) { Asynchronic::QueueEngine::InMemory::Listener.new }

  it 'Container' do
    container.queues.must_be_empty
    
    queue = container[:test_access]
    queue.must_be_instance_of Asynchronic::QueueEngine::InMemory::Queue
    container.queues.must_equal [:test_access]
    
    container[:test_access].must_equal queue
    
    container.clear
    container.queues.must_be_empty
  end

  it 'Queue (push/pop)' do
    queue.must_be_empty
    
    queue.push 'msg_1'
    queue.push 'msg_2'
    
    queue.size.must_equal 2
    queue.to_a.must_equal %w(msg_2 msg_1)

    msg = queue.pop

    msg.must_equal 'msg_1'

    queue.size.must_equal 1
    queue.to_a.must_equal %w(msg_2)
  end

  it 'Listener' do
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