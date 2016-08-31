module Asynchronic
  module DataStore
    class InMemory

      include Helper

      def initialize(hash={})
        @hash = {}
        @mutex = Mutex.new
        self.class.connections[object_id] = self
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
        @hash.keys.map { |k| Key.new k }
      end

      def connection_args
        [object_id]
      end

      def self.connect(object_id)
        connections[object_id]
      end

      private

      def self.connections
        @connections ||= {}
      end

    end
  end
end