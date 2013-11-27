module Asynchronic
  module Persistent

    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods

      def id
        @id
      end
      
      def save
        @id ||= SecureRandom.uuid
        namespace[id].set Marshal.dump(self)
      end

      def delete
        namespace[id].del
      end

      def namespace
        self.class.namespace
      end

    end

    module ClassMethods
      
      def create(*args, &block)
        new(*args, &block).tap(&:save)
      end

      def delete(id)
        namespace[id].del
      end

      def find(id)
        Marshal.load namespace[id].get
      end

      def namespace
        @namespace ||= Nest.new self.name, Asynchronic.redis
      end

    end

  end
end