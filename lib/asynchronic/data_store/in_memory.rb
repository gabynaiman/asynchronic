module Asynchronic
  module DataStore
    class InMemory

      def initialize
        @hash = {}
      end

      def get(key)
        @hash[key.to_s]
      end

      def set(key, value)
        @hash[key.to_s] = value
      end

      def keys(key=nil)
        key ? keys.select { |k| k.start_with? key.to_s } : @hash.keys
      end

      def clear(key=nil)
        if key
          @hash.delete_if { |k,v| k.start_with? key.to_s }
        else
          @hash.clear
        end
      end

    end
  end
end