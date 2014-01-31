module Asynchronic
  module DataStore
    class Key < String
    
      def initialize(key, separator=':')
        super key.to_s
        @separator = separator
      end

      def [](key)
        self.class.new "#{self}#{@separator}#{key}"
      end

    end
  end
end