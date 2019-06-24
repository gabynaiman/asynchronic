module Asynchronic
  module Notifier
    class Broadcaster

      def initialize(options={})
        options[:logger] ||= Asynchronic.logger
        @broadcaster = ::Broadcaster.new options
      end

      def publish(pid, event, data=nil)
        @broadcaster.publish DataStore::Key[pid][event], data
      end

      def subscribe(pid, event, &block)
        @broadcaster.subscribe DataStore::Key[pid][event] do |data|
          block.call data
        end
      end

      def unsubscribe(subscription_id)
        @broadcaster.unsubscribe subscription_id
      end

      def unsubscribe_all
        @broadcaster.unsubscribe_all
      end

    end
  end
end