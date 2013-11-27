module Asynchronic
  class Process

    include Persistent

    Child = Struct.new :status, :output

    attr_reader :pipeline
    attr_reader :context
    attr_reader :children
  
    def initialize(pipeline, context={})
      @pipeline = pipeline
      @context = context
      @children = pipeline.steps.map { Child.new :pending }
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

          enqueue(pipeline.steps[next_child(i)].options[:queue]) if next_child?(i)
        end
      end
    end

    def self.enqueue(pipeline, context={})
      process = Process.create pipeline, context
      process.enqueue(pipeline.steps.first.options[:queue])
      process.id
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
      Asynchronic.logger.info "#{message} - Start"
      result = yield
      Asynchronic.logger.info "#{message} - End (Time: #{Time.now - start})"
      result
    end

  end
end