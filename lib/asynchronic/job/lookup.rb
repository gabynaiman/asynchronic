module Asynchronic
  class Job
    class Lookup

      def initialize(specification)
        @specification = specification
      end

      def job
        if @specification.parent 
          DataStore::Key.new(@specification.parent)[:jobs][@specification.id]
        else
          DataStore::Key.new(:asynchronic)[:job][@specification.id]
        end
      end

      def status
        job[:status]
      end

      def data
        job[:data]
      end

      def jobs
        job[:jobs]
      end

      def error
        job[:error]
      end

    end
  end
end