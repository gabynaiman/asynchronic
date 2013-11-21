module Asynchronic
  class Process

    include Persistent

    Child = Struct.new :status, :output

    attr_reader :pipeline
    attr_reader :input
    attr_reader :children
  
    def initialize(pipeline, input)
      @pipeline = pipeline
      @input = input
      @children = pipeline.steps.map { Child.new :pending }
    end

    def context
      @context ||= {}
    end

    def enqueue
      Ost[pipeline.queue || Asynchronic.default_queue].push id
    end

    def run
      current_child.tap do |i|
        children[i].status = :running
        save

        current_input = previous_child?(i) ? children[previous_child(i)].output : input
        children[i].output = pipeline.steps[i].block.call(current_input, context)
        children[i].status = :finalized
        save

        enqueue if next_child?(i)
      end
    end

    def self.enqueue(pipeline, input)
      process = Process.create pipeline, input
      process.enqueue
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

  end
end