module Asynchronic
  class Key < String

    SEPARATOR = ':'
    
    def initialize(key, data_store)
      super key.to_s
      @data_store = data_store
    end

    def [](key)
      self.class.new "#{children_key}#{key}", @data_store
    end

    [:get, :set, :clear].each do |method|
      define_method method do |*args, &block|
        @data_store.send method, self, *args, &block
      end
    end

    def keys
      @data_store.keys children_key
    end

    def merge(hash)
      hash.each { |k,v| self[k].set v }
    end

    def to_hash
      keys.inject({}) do |hash, key|
        hash[key[children_key.size..-1]] = @data_store.get key
        hash
      end
    end

    private

    def children_key
      "#{self}#{SEPARATOR}"
    end

  end
end