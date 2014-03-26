module Asynchronic
  module DataStore
    class LazyValue < BasicObject

      instance_methods.reject { |m| m == :__send__ }.
                       each   { |m| undef_method m }

      def initialize(data_store, key)
        @__data_store__ = data_store
        @__key__ = key
      end

      def reload
        @__value__ = nil
        self
      end

      def inspect
        "#<Asynchronic::DataStore::LazyValue data_store=#{@__data_store__.class}, key='#{@__key__}'>"
      end

      private

      def method_missing(method, *args, &block)
        __value__.send(method, *args, &block)
      end

      def __value__
        @__value__ ||= @__data_store__.get(@__key__)
      end

    end
  end
end