module Asynchronic
  module DataStore
    class Key < String
    
      def initialize(key)
        super key.to_s
      end

      def [](key)
        self.class.new "#{self}:#{key}"
      end

    end
  end
end