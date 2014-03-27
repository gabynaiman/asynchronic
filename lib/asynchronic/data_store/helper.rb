module Asynchronic
  module DataStore
    module Helper

      include Enumerable

      def each
        keys.each { |k| yield [k, self[k]] }
        nil
      end

      def merge(hash)
        hash.each { |k,v| self[k] = v }
      end

      def clear
        keys.each { |k| delete k }
      end

      def scoped(key)
        ScopedStore.new self, key
      end

      def readonly?
        false
      end

      def readonly
        ReadonlyStore.new self
      end

      def lazy?
        false
      end

      def lazy
        LazyStore.new self
      end

    end
  end
end