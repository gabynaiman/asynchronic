module Asynchronic
  module DataStore
    class Redis

      include Helper

      def initialize(*args)
        @connection = ::Redis.new *args
      end

      def [](key)
        value = @connection.get key.to_s
        value ? Marshal.load(value) : nil
      rescue => ex
        Asynchronic.logger.warn('Asynchronic') { ex.message }
        value
      end

      def []=(key, value)
        @connection.set key.to_s, Marshal.dump(value)
      end

      def delete(key)
        @connection.del key.to_s
      end

      def keys
        @connection.keys.map { |k| Key.new k }
      end
      
    end
  end
end