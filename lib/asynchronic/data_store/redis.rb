module Asynchronic
  module DataStore
    class Redis

      LOCKED = 'locked'

      include Helper

      def self.connect(*args)
        new(*args)
      end

      def initialize(scope, options={})
        @scope = Key[scope]
        @options = options
      end

      def [](key)
        value = redis.call! 'GET', scope[key]
        value ? Marshal.load(value) : nil
      rescue => ex
        Asynchronic.logger.warn('Asynchronic') { ex.message }
        value
      end

      def []=(key, value)
        redis.call! 'SET', scope[key], Marshal.dump(value)
      end

      def delete(key)
        redis.call! 'DEL', scope[key]
      end

      def delete_cascade(key)
        redis.call! 'DEL', scope[key]
        redis.call!('KEYS', scope[key]['*']).each { |k| redis.call! 'DEL', k }
      end

      def keys
        redis.call!('KEYS', scope['*']).map { |k| Key[k].remove_first }
      end

      def synchronize(key)
        while redis.call!('GETSET', scope[key][LOCKED], LOCKED) == LOCKED
          sleep Asynchronic.redis_data_store_sync_timeout
        end
        yield
      ensure
        redis.call! 'DEL', scope[key][LOCKED]
      end

      def connection_args
        [scope, options]
      end

      private

      attr_reader :scope, :options

      def redis
        @redis ||= Asynchronic.establish_redis_connection options
      end

    end
  end
end