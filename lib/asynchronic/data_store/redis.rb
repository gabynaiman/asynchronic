module Asynchronic
  module DataStore
    class Redis

      include Helper

      def initialize(*args)
        @connection = ::Redis.new *args
      end

      def [](key)
        value = @connection.get root[key]
        value ? Marshal.load(value) : nil
      rescue => ex
        Asynchronic.logger.warn('Asynchronic') { ex.message }
        value
      end

      def []=(key, value)
        @connection.set root[key], Marshal.dump(value)
      end

      def keys(key=nil)
        keys = key ? @connection.keys("#{root[key]}*") : @connection.keys
        keys.map { |k| k[(root.size + 1)..-1] }
      end

      def clear(key=nil)
        keys(key).each { |k| @connection.del root[k] }
      end

      private

      def root
        Key.new :asynchronic
      end
      
    end
  end
end