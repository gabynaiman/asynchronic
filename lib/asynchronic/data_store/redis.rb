module Asynchronic
  module DataStore
    class Redis

      include Helper

      def initialize(scope, *args)
        @scope = Key.new scope
        @connection = ::Redis.new *args
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

      def keys
        @connection.keys(@scope['*']).map { |k| Key.new(k).remove_first }
      end

      def connection_args
        [@scope, @connection.client.options]
      end

      def self.connect(*args)
        new *args
      end
      
    end
  end
end