module Asynchronic
  module DataStore
    class LazyValue < TransparentProxy

      def initialize(data_store, key)
        @data_store_class = data_store.class
        @data_store_connection = data_store.connection
        @key = key
      end

      def reload
        @value = nil
        self
      end

      def inspect
        "#<#{proxy_class} @data_store_class=#{@data_store_class} @data_store_connection=#{@data_store_connection} @key=#{@key}>"
      end

      def data_store
        @data_store_class.connect @data_store_connection
      end

      def to_value
        __getobj__
      end

      private

      def __getobj__
        @value ||= data_store[@key]
      end

    end
  end
end