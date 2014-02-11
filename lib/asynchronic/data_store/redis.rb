module Asynchronic
  module DataStore
    class Redis

      attr_reader :connection

      def initialize(*args)
        @connection = ::Redis.new *args
      end

      def get(key)
        value = connection.get root[key]
        value ? Marshal.load(value) : nil
      end

      def set(key, value)
        connection.set root[key], Marshal.dump(value)
      end

      def merge(key, hash)
        scoped_key = Key.new key
        hash.each do |k,v|
          set scoped_key[k], v
        end
      end

      def to_hash(key)
        children_key = "#{key}:"
        keys(children_key).inject({}) do |hash, k|
          hash[k[children_key.size..-1]] = get k
          hash
        end
      end

      def keys(key=nil)
        keys = key ? connection.keys("#{root[key]}*") : connection.keys
        keys.map { |k| k[(root.size + 1)..-1] }
      end

      def clear(key=nil)
        keys(key).each { |k| connection.del root[k] }
      end

      private

      def root
        Key.new :asynchronic
      end
      
    end
  end
end