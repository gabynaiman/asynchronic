module Asynchronic
  module DataStore
    class Redis

      LOCKED = 'locked'

      include Helper

      def initialize(scope, *args)
        @scope = Key[scope]
        @connection = ::Redis.new(*args)
      end

      def [](key)
        value = @connection.get @scope[key]
        value ? Marshal.load(value) : nil
      rescue => ex
        Asynchronic.logger.warn('Asynchronic') { ex.message }
        value
      end

      def []=(key, value)
        @connection.set @scope[key], Marshal.dump(value)
      end

      def delete(key)
        @connection.del @scope[key]
      end

      def delete_cascade(key)
        @connection.del @scope[key]
        @connection.keys(@scope[key]['*']).each { |k| @connection.del k }
      end

      def keys
        @connection.keys(@scope['*']).map { |k| Key[k].remove_first }
      end

      def synchronize(key)
        while @connection.getset(@scope[key][LOCKED], LOCKED) == LOCKED
          sleep Asynchronic.redis_data_store_sync_timeout
        end
        yield
      ensure
        @connection.del @scope[key][LOCKED]
      end

      def connection_args
        [@scope, @connection.client.options]
      end

      def self.connect(*args)
        new(*args)
      end
      
    end
  end
end