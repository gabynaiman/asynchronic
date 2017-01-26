module Asynchronic
  module DataStore
    class ScopedStore

      include Helper

      attr_reader :data_store
      attr_reader :scope
      
      def initialize(data_store, scope)
        @data_store = data_store
        @scope = Key.new scope
      end

      def [](key)
        @data_store[@scope[key]]
      end

      def []=(key, value)
        @data_store[@scope[key]] = value
      end

      def delete(key)
        @data_store.delete @scope[key]
      end

      def keys
        @data_store.keys.
          select { |k| k.start_with? @scope[''] }.
          map { |k| Key.new(k).remove_first @scope.sections.count }
      end

      def synchronize(key, &block)
        data_store.synchronize(key, &block)
      end

      def connection_args
        [
          {
            data_store_class: @data_store.class,
            data_store_connection_args: @data_store.connection_args,
            scope: @scope
          }
        ]
      end

      def self.connect(*args)
        data_store = args[0][:data_store_class].connect *args[0][:data_store_connection_args]
        new data_store, args[0][:scope]
      end

      def to_s
        "#<#{self.class} @data_store=#{@data_store} @scope=#{@scope}>"
      end

    end
  end
end