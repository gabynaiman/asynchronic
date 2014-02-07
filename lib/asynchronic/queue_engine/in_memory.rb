module Asynchronic
  module QueueEngine
    class InMemory

      attr_reader :default_queue

      def initialize(options={})
        @default_queue = options.fetch(:default_queue, Asynchronic.default_queue)
        @queues ||= Hash.new { |h,k| h[k] = Queue.new }
      end

      def [](name)
        @queues[name]
      end

      def queues
        @queues.keys.map(&:to_sym)
      end

      def clear
        @queues.clear
      end

      def listener
        Listener.new
      end


      class Queue

        extend Forwardable

        def_delegators :@queue, :size, :empty?, :to_a

        def initialize
          @queue = []
          @mutex = Mutex.new
        end

        def pop
          @mutex.synchronize { @queue.shift }
        end

        def push(message)
          @mutex.synchronize { @queue.push message }
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