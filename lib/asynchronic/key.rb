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

    [:get, :set].each do |method|
      define_method method do |*args, &block|
        @data_store.send method, self, *args, &block
      end
    end

    [:keys, :clear].each do |method|
      define_method method do |*args, &block|
        @data_store.send method, *args, &block
      end
    end

    def merge(hash)
      hash.each { |k,v| self[k].set v }
    end

    def to_hash
      keys(children_key).inject({}) do |hash, key|
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