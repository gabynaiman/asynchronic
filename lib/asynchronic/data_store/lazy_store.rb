require_relative '../transparent_proxy'

module Asynchronic
  module DataStore
    class LazyStore < TransparentProxy

      def [](key)
        LazyValue.new __getobj__, key
      end

      def lazy?
        true
      end

    end
  end
end