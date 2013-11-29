class Registry
  extend Enumerable

  def self.add(arg)
    Asynchronic.logger.debug('Asynchronic') { "Registry: #{arg}" }
    elements << arg
    arg
  end

  def self.clear
    elements.clear
  end

  def self.each(&block)
    elements.each(&block)
  end

  def self.empty?
    !any?
  end

  private

  def self.elements
    @elements ||= []
  end
end

class SingleStepJob
  extend Asynchronic::Pipeline
  step :step_name do
    Registry.add :single_step_job
  end
end

class TwoStepsWithSpecificQueueJob
  extend Asynchronic::Pipeline
  queue :specific_queue
  step :first do |ctx|
    ctx[:value2] = ctx[:value1] / 2
    Registry.add ctx[:value1] + 1
  end
  step :second do |ctx, input|
    Registry.add input * ctx[:value2]
  end
end

class MultipleQueuesJob
  extend Asynchronic::Pipeline
  step :first_queue, queue: :queue1 do
    Registry.add :first_queue
  end
  step :second_queue, queue: ->(ctx){ctx[:dynamic_queue]} do
    Registry.add :second_queue
  end
end


