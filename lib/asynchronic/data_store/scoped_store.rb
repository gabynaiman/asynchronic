module Asynchronic
  module DataStore
    class ScopedStore

      include Helper

      attr_reader :data_store, :scope

      def self.connect(options)
        data_store = options[:data_store_class].connect(*options[:data_store_connection_args])
        new data_store, options[:scope]
      end

      def initialize(data_store, scope)
        @data_store = data_store
        @scope = Key[scope]
      end

      def [](key)
        data_store[scope[key]]
      end

      def []=(key, value)
        data_store[scope[key]] = value
      end

      def delete(key)
        data_store.delete scope[key]
      end

      def delete_cascade
        data_store.delete_cascade scope
      end

      def keys
        @data_store.keys.
          select { |k| k.start_with? scope[''] }.
          map { |k| Key[k].remove_first scope.sections.count }
      end

      def synchronize(key, &block)
        data_store.synchronize(key, &block)
      end

      def connection_args
        [
          {
            data_store_class: data_store.class,
            data_store_connection_args: data_store.connection_args,
            scope: scope
          }
        ]
      end

      def to_s
        "#<#{self.class} @data_store=#{data_store} @scope=#{scope}>"
      end

    end
  end
end