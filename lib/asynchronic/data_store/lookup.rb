module Asynchronic
  module DataStore
    class Lookup

      KEYS = [:status, :data, :jobs, :error, :created_at, :queued_at, :started_at, :finalized_at]

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

      KEYS.each do |key|
        define_method key do
          id[key]
        end
      end

    end
  end
end