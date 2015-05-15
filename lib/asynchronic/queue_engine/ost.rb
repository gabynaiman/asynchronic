module Asynchronic
  module QueueEngine
    class Ost
      
      attr_reader :default_queue

      def initialize(options={})
        ::Ost.connect options[:redis] if options.key?(:redis)
        @default_queue = options[:default_queue]
        @queues ||= Hash.new { |h,k| h[k] = Queue.new k }
      end

      def default_queue
        @default_queue ||= Asynchronic.default_queue
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

      def listener
        Listener.new
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
          !redis.exists(key)
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
          Asynchronic.retry_execution(self.class, 'listen') do
            queue.each &block
          end
        end

        def stop
          @current_queue.stop
        end

      end

    end
  end
end