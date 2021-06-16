module Asynchronic
  module DataStore
    class InMemory

      include Helper

      def self.connect(object_id)
        connections[object_id]
      end

      def self.connections
        @connections ||= {}
      end

      def initialize
        @hash = {}
        @mutex = Mutex.new
        @keys_mutex = Hash.new { |h,k| h[k] = Mutex.new }
        self.class.connections[object_id] = self
      end

      def [](key)
        Marshal.load(hash[key.to_s]) if hash.key? key.to_s
      end

      def []=(key, value)
        mutex.synchronize { hash[key.to_s] = Marshal.dump(value) }
      end

      def delete(key)
        hash.delete key.to_s
      end

      def delete_cascade(key)
        keys.select { |k| k.sections.first == key }
            .each { |k| delete k }
      end

      def keys
        hash.keys.map { |k| Key[k] }
      end

      def synchronize(key, &block)
        keys_mutex[key].synchronize(&block)
      end

      def connection_args
        [object_id]
      end

      private

      attr_reader :hash, :mutex, :keys_mutex

    end
  end
end