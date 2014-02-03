module Asynchronic
  module QueueEngine
    class InMemory

      def initialize
        @queues ||= Hash.new { |h,k| h[k] = Queue.new }
      end

      def [](name)
        @queues[name]
      end

      def queues
        @queues.keys
      end

      def clear
        @queues.clear
      end


      class Queue < ::Queue

        def to_a
          @que.dup
        end

        def pop
          super rescue nil
        end

      end


      class Listener

        def listen(queue, &block)
          @stopping = false

          loop do
            break if @stopping
            item = queue.pop
            next unless item
            block.call item
          end
        end

        def stop
          @stopping = true
        end

      end

    end
  end
end