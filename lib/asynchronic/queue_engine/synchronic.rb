module Asynchronic
  module QueueEngine
    class Synchronic

      attr_reader :stubs

      def initialize(options={})
        @options = options
        @stubs = {}
      end

      def default_queue
        Asynchronic.default_queue
      end

      def environment
        @environment ||= options.fetch(:environment, Asynchronic.environment)
      end

      def [](name)
        Queue.new self
      end

      def stub(job, &block)
        stubs[job] = block
      end

      def asynchronic?
        false
      end

      def active_connections
        [Asynchronic.connection_name]
      end

      private

      attr_reader :options


      class Queue

        def initialize(engine)
          @engine = engine
        end

        def push(message)
          process = engine.environment.load_process(message)

          if engine.stubs[process.type]
            job = process.job
            block = engine.stubs[process.type]
            process.define_singleton_method :job do
              MockJob.new job, process, &block
            end
          end

          process.execute
        end

        private

        attr_reader :engine

      end


      class MockJob < TransparentProxy

        def initialize(job, process, &block)
          super job
          @process = process
          @block = block
        end

        def call
          block.call process
        end

        def before_finalize
        end

        private

        attr_reader :process, :block

      end

    end
  end
end