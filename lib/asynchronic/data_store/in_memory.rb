module Asynchronic
  module DataStore
    class InMemory

      def initialize
        @hash = {}
        @mutex = Mutex.new
      end

      def get(key)
        @hash[key.to_s]
      end

      def set(key, value)
        @mutex.synchronize { @hash[key.to_s] = value }
      end

      def merge(key, hash)
        scoped_key = Key.new key
        hash.each do |k,v|
          set scoped_key[k].to_s, v
        end
      end

      def to_hash(key)
        children_key = "#{key}:"
        keys(children_key).inject({}) do |hash, k|
          hash[k[children_key.size..-1]] = get k
          hash
        end
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