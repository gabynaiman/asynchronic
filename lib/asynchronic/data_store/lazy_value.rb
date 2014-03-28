require_relative '../transparent_proxy'

module Asynchronic
  module DataStore
    class LazyValue < TransparentProxy

      def initialize(data_store, key)
        @data_store = data_store
        @key = key
      end

      def reload
        @value = nil
        self
      end

      def inspect
        "#<#{proxy_class} @data_store=#{@data_store} @key=#{@key}>"
      end

      private

      def __getobj__
        @value ||= @data_store[@key]
      end

    end
  end
end