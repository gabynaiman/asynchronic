module Asynchronic
  module QueueEngine
    class Ost

      attr_reader :default_queue

      def initialize(options={})
        @redis = Redic.new(*Array(options[:redis]))
        @default_queue = options.fetch(:default_queue, Asynchronic.default_queue)
        @queues ||= Hash.new { |h,k| h[k] = Queue.new k }
        @keep_alive_thread = notify_keep_alive
      end

      def [](name)
        @queues[name]
      end

      def queues
        (@queues.values.map(&:key) | @redis.call('KEYS', 'ost:*')).map { |q| q.to_s[4..-1].to_sym }
      end

      def clear
        @queues.clear
        @redis.call('KEYS', 'ost:*').each { |k| @redis.call('DEL', k) }
      end

      def listener
        Listener.new
      end

      def asynchronic?
        true
      end

      def active_connections
        @redis.call('CLIENT', 'LIST').split("\n").map do |connection_info|
          connection_info.split(' ').detect { |a| a.match(/name=/) }[5..-1]
        end.uniq.reject(&:empty?)
      end

      private

      def notify_keep_alive
        Thread.new do
          loop do
            @redis.call 'CLIENT', 'SETNAME', Asynchronic.connection_name
            sleep Asynchronic.keep_alive_timeout
          end
        end
      end


      class Queue < ::Ost::Queue

        def pop
          redis.call 'RPOP', key
        end

        def empty?
          redis.call('EXISTS', key) == 0
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
            queue.each(&block)
          end
        end

        def stop
          @current_queue.stop
        end

      end

    end
  end
end