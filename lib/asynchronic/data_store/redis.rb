module Asynchronic
  module DataStore
    class Redis

      LOCKED = 'locked'

      include Helper

      def initialize(scope, *args)
        @scope = Key[scope]
        @redis = Redic.new(*args)
      end

      def [](key)
        value = @redis.call 'GET', @scope[key]
        value ? Marshal.load(value) : nil
      rescue => ex
        Asynchronic.logger.warn('Asynchronic') { ex.message }
        value
      end

      def []=(key, value)
        @redis.call 'SET', @scope[key], Marshal.dump(value)
      end

      def delete(key)
        @redis.call 'DEL', @scope[key]
      end

      def delete_cascade(key)
        @redis.call 'DEL', @scope[key]
        @redis.call('KEYS', @scope[key]['*']).each { |k| @redis.call 'DEL', k }
      end

      def keys
        @redis.call('KEYS', @scope['*']).map { |k| Key[k].remove_first }
      end

      def synchronize(key)
        while @redis.call('GETSET', @scope[key][LOCKED], LOCKED) == LOCKED
          sleep Asynchronic.redis_data_store_sync_timeout
        end
        yield
      ensure
        @redis.call 'DEL', @scope[key][LOCKED]
      end

      def connection_args
        [@scope, @redis.url]
      end

      def self.connect(*args)
        new(*args)
      end
      
    end
  end
end