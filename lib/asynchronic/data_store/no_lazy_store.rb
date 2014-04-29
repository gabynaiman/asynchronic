module Asynchronic
  module DataStore
    class NoLazyStore < TransparentProxy

      include Helper

      def [](key)
        value = __getobj__[key]
        value.respond_to?(:proxy?) ? value.reload.to_value : value
      end

      def lazy?
        false
      end

    end
  end
end