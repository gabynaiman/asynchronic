module Asynchronic
  module QueueEngine
    class Ost
      
      def initialize
        @queues ||= Hash.new { |h,k| h[k] = Queue.new k }
      end

      def [](name)
        @queues[name]
      end

      def queues
        (@queues.values.map(&:key) | redis.keys('ost:*')).map { |q| q.to_s[4..-1].to_sym }
      end

      def clear
        @queues.clear
        redis.keys('ost:*').each { |k| redis.del k }
      end

      private

      def redis
        @redis ||= Redis.connect(::Ost.options)
      end


      class Queue < ::Ost::Queue

        def pop
          key.rpop
        end

        def empty?
          items.empty?
        end

        def size
          items.count
        end

        def to_a
          items.reverse
        end

      end


      class Listener

        def listen(queue, &block)
          @current_queue = queue
          queue.each &block
        end

        def stop
          @current_queue.stop
        end

      end

    end
  end
end