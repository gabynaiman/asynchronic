module Asynchronic
  module DataStore
    module Helper

      def merge(key, hash)
        scoped_key = Key.new key
        hash.each do |k,v|
          self[scoped_key[k]] = v
        end
      end

      def to_hash(key)
        children_key = "#{key}#{Key::SEPARATOR}"
        keys(children_key).inject(HashWithIndiferentAccess.new) do |hash, k|
          hash[k[children_key.size..-1]] = self[k]
          hash
        end
      end

    end
  end
end