module Asynchronic
  module DataStore
    class LazyStore < TransparentProxy

      include Helper

      def [](key)
        LazyValue.new __getobj__, key
      end

      def lazy?
        true
      end

    end
  end
end