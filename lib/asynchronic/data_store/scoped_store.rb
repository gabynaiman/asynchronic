module Asynchronic
  module DataStore
    class ScopedStore

      include Helper
      
      def initialize(data_store, scope)
        @data_store = data_store
        @scope = Key.new scope
        @readonly = false
      end

      def [](key)
        LazyValue.new @data_store, @scope[key]
      end

      def []=(key, value)
        raise "Can't modify read only ScopedStore ['#{@scope}|#{key}' => #{value}]" if @readonly
        @data_store[@scope[key]] = value
      end

      def keys(key=nil)
        @data_store.keys key ? @scope[key] : @scope
      end

      def clear(key=nil)
        @data_store.clear key ? @scope[key] : @scope
      end

      def readonly
        @readonly = true
        self
      end

    end
  end
end