module Asynchronic
  module DataStore
    class Lookup

      def initialize(job)
        @job = job
      end

      def id
        if @job.parent 
          DataStore::Key.new(@job.parent)[:jobs][@job.id]
        else
          DataStore::Key.new(:job)[@job.id]
        end
      end

      def status
        id[:status]
      end

      def data
        id[:data]
      end

      def jobs
        id[:jobs]
      end

      def error
        id[:error]
      end

    end
  end
end