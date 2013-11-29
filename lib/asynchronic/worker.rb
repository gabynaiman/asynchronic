module Asynchronic
  class Worker

    attr_reader :queue

    def initialize(queue=nil)
      @queue = queue || Asynchronic.default_queue
    end

    def start
      Signal.trap('INT') { stop }

      Ost[@queue].pop do |pid|
        Process.find(pid).run
      end
    end

    def stop
      Ost[@queue].stop
    end

    def self.start(queue=nil)
      new(queue).tap(&:start)
    end
  
  end
end