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

      def archive
        FileUtils.mkpath(Asynchronic.archiving_path) unless Dir.exists?(Asynchronic.archiving_path)
        File.write File.join(Asynchronic.archiving_path, "#{id}.bin"), Base64.encode64(Marshal.dump(self))
        delete
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
        if namespace[id].get
          Marshal.load namespace[id].get
        elsif File.exists?(File.join(Asynchronic.archiving_path, "#{id}.bin"))
          Marshal.load(Base64.decode64(File.read(File.join(Asynchronic.archiving_path, "#{id}.bin"))))
        else
          nil
        end
      end

      def namespace
        @namespace ||= Nest.new self.name, Asynchronic.redis
      end

    end

  end
end