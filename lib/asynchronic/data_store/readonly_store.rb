module Asynchronic
  module DataStore
    class ReadonlyStore < TransparentProxy

      include Helper

      def []=(key, value)
        raise "Can't modify read only data store"
      end

      def readonly?
        true
      end

    end
  end
end