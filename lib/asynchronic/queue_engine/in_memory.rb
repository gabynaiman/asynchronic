module Asynchronic
  module QueueEngine
    module InMemory

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


      class Container

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

      end

    end
  end
end