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

      def connection
        {
          data_store_class: @data_store.class,
          data_store_connection: @data_store.connection,
          scope: @scope
        }
      end

      def self.connect(options)
        data_store = options[:data_store_class].connect options[:data_store_connection]
        new data_store, options[:scope]
      end

      def to_s
        "#<#{self.class} @data_store=#{@data_store} @scope=#{@scope}>"
      end

    end
  end
end