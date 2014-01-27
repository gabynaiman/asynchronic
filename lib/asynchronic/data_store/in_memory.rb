module Asynchronic
  module DataStore
    module InMemory

      class DB

        def initialize
          @hash = {}
        end

        def get(key)
          @hash[key]
        end

        def [](key)
          Key.new(self, key)
        end

        def set(key, value)
          @hash[key] = value
        end

        def keys
          @hash.keys
        end

        def merge!(hash)
          @hash.merge! hash
        end

        def clear
          @hash.clear
        end

      end

      class Key

        attr_reader :key

        def initialize(db, key, parent=nil)
          @db = db
          @key = key
          @parent = parent
        end

        def [](key)
          self.class.new @db, key, self
        end

        def get
          @db.get to_s
        end

        def set(value)
          @db.set to_s, value
        end

        def to_s
          @parent ? "#{@parent.to_s}:#{@key.to_s}" : @key.to_s
        end
        
      end
      
    end
  end
end