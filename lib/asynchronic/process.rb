module Asynchronic
  class Process

    include Persistent

    Child = Struct.new :status, :output

    attr_reader :pipeline
    attr_reader :context
    attr_reader :children
    attr_reader :errors
  
    def initialize(pipeline, context={})
      @pipeline = pipeline
      @context = context
      @children = pipeline.steps.map { Child.new :pending }
      @errors = []
    end

    def enqueue(queue=nil)
      q = queue || pipeline.queue || Asynchronic.default_queue
      Ost[q.is_a?(Proc) ? q.call(context) : q].push id
    end

    def run
      current_child.tap do |i|
        log "Running: #{id} (child: #{i})" do
          children[i].status = :running
          save

          current_input = previous_child?(i) ? children[previous_child(i)].output : nil
          children[i].output = pipeline.steps[i].block.call(context, current_input)
          children[i].status = :finalized
          save

          if next_child?(i)
            enqueue(pipeline.steps[next_child(i)].options[:queue])
          else
            archive
          end
        end
      end
    end

    def output
      children.last.output
    end

    def finalized?
      children.map(&:status).uniq == [:finalized]
    end

    def success?
      finalized? && errors.empty?
    end

    def self.enqueue(pipeline, context={})
      process = Process.create pipeline, context
      process.enqueue(pipeline.steps.first.options[:queue])
      process.id
    end

    def self.wait(pid, seconds=3600)
      timeout(seconds) do
        loop do
          process = find pid
          break if process.finalized?
          sleep 0.2
        end
      end
      find pid
    end

    private

    def current_child
      children.index { |c| c.status == :pending }
    end

    def previous_child(index=current_step)
      index - 1
    end

    def previous_child?(index=current_step)
      previous_child(index) >= 0
    end

    def next_child(index=current_step)
      index + 1
    end

    def next_child?(index=current_step)
      next_child(index) < children.count
    end

    def log(message)
      start = Time.now
      Asynchronic.logger.info('Asynchronic') { "#{message} - Start" }
      result = yield
      Asynchronic.logger.info('Asynchronic') { "#{message} - End (Time: #{Time.now - start})" }
      Asynchronic.logger.debug('Asynchronic') { inspect }
      result
    end

  end
end