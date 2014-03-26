module Asynchronic
  module DataStore
    class LazyValue < BasicObject

      instance_methods.reject { |m| m == :__send__ }.
                       each   { |m| undef_method m }

      def initialize(data_store, key)
        @data_store = data_store
        @key = key
      end

      def reload
        @value = nil
        self
      end

      def inspect
        "#<Asynchronic::DataStore::LazyValue data_store=#{@data_store.class}, key='#{@key}'>"
      end

      private

      def method_missing(method, *args, &block)
        __value__.send(method, *args, &block)
      end

      def __value__
        @value ||= @data_store[@key]
      end

    end
  end
end