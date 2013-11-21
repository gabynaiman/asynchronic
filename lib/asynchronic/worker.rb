module Asynchronic
  class Worker

    def initialize(queue)
      @queue = queue
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
  
  end
end