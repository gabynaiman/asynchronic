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

      def listen(queue, &block)
        Listener.new.tap { |l| l.listen queue, &block }
      end


      class Queue < ::Queue

        def to_a
          @que.dup.reverse
        end

        def pop
          super
        rescue Exception
          nil
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