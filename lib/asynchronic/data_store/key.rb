module Asynchronic
  module DataStore
    class Key < String
    
      SEPARATOR = '|'

      def self.[](key)
        new key
      end
      
      def initialize(key)
        super key.to_s
      end

      def [](key)
        self.class.new [self,key].join(SEPARATOR)
      end

      def sections
        split SEPARATOR
      end

      def nested?
        sections.count > 1
      end

      def remove_first(count=1)
        self.class.new sections[count..-1].join(SEPARATOR)
      end

      def remove_last(count=1)
        self.class.new sections[0..-count-1].join(SEPARATOR)
      end

    end
  end
end