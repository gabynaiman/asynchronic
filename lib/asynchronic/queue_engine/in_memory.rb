module Asynchronic
  module QueueEngine
    class InMemory

      def initialize(options={})
        @options = options
        @queues ||= Hash.new { |h,k| h[k] = Queue.new }
      end

      def default_queue
        @default_queue ||= options.fetch(:default_queue, Asynchronic.default_queue)
      end

      def [](name)
        queues[name]
      end

      def queue_names
        queues.keys.map(&:to_sym)
      end

      def clear
        queues.clear
      end

      def listener
        Listener.new
      end

      def asynchronic?
        true
      end

      def active_connections
        [Asynchronic.connection_name]
      end

      private

      attr_reader :queues, :options


      class Queue

        extend Forwardable

        def_delegators :queue, :size, :empty?, :to_a

        def initialize
          @queue = []
          @mutex = Mutex.new
        end

        def pop
          mutex.synchronize { queue.shift }
        end

        def push(message)
          mutex.synchronize { queue.push message }
        end

        private

        attr_reader :queue, :mutex

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