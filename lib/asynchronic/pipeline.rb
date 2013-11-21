module Asynchronic
  module Pipeline

    Step = Struct.new :name, :options, :block

    def queue(name=nil)
      name ? @queue = name : @queue
    end

    def step(name, options={}, &block)
      steps << Step.new(name, options, block)
    end

    def steps
      @steps ||= []
    end

    def run(input)
      Process.enqueue self, input
    end

  end
end