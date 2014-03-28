module Asynchronic
  module DataStore
    class ScopedStore

      include Helper
      
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

      def to_s
        "#<#{self.class} @data_store=#{@data_store} @scope=#{@scope}>"
      end

    end
  end
end