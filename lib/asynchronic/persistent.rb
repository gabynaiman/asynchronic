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
        nest.set Marshal.dump(self)
      end

      def delete
        return unless id
        nest.del
      end

      def archive
        return unless id
        FileUtils.mkpath(Asynchronic.archiving_path) unless Dir.exists?(Asynchronic.archiving_path)
        File.write Asynchronic.archiving_file(id), Base64.encode64(Marshal.dump(self))
        delete
      end

      def nest
        self.class.nest[id]
      end

    end

    module ClassMethods
      
      def create(*args, &block)
        new(*args, &block).tap(&:save)
      end

      def find(id)
        if nest[id].get
          Marshal.load nest[id].get
        elsif File.exists?(Asynchronic.archiving_file(id))
          Marshal.load(Base64.decode64(File.read(Asynchronic.archiving_file(id))))
        else
          nil
        end
      end

      def nest
        @nest ||= Nest.new self.name, Asynchronic.redis
      end

    end

  end
end