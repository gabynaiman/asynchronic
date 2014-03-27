module Asynchronic
  module DataStore
    class InMemory

      include Helper

      def initialize
        @hash = {}
        @mutex = Mutex.new
      end

      def [](key)
        @hash[key.to_s]
      end

      def []=(key, value)
        @mutex.synchronize { @hash[key.to_s] = value }
      end

      def delete(key)
        @hash.delete key.to_s
      end

      def keys
        @hash.keys
      end

    end
  end
end