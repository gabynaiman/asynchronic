module Asynchronic
  module Notifier
    class InMemory

      def publish(pid, event, data=nil)
        subscriptions[DataStore::Key[pid][event]].each_value do |block|
          block.call data
        end
      end

      def subscribe(pid, event, &block)
        SecureRandom.uuid.tap do |subscription_id|
          subscriptions[DataStore::Key[pid][event]][subscription_id] = block
        end
      end

      def unsubscribe(subscription_id)
        subscriptions.each_value { |s| s.delete subscription_id }
      end

      def unsubscribe_all
        subscriptions.clear
      end

      private

      def subscriptions
        @subscriptions ||= Hash.new { |h,k| h[k] = {} }
      end

    end
  end
end
