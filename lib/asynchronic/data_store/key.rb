module Asynchronic
  module DataStore
    class Key < String
    
      SEPARATOR = '|'
      
      def initialize(key)
        super key.to_s
      end

      def [](key)
        self.class.new [self,key].join(SEPARATOR)
      end

      def sections
        split SEPARATOR
      end

    end
  end
end