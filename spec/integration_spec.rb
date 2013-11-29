require 'minitest_helper'
require 'jobs'

describe 'Integration' do

  before do
    Registry.clear
  end

  def start_and_stop_worker(queue=nil)
    worker = Asynchronic::Worker.new queue
    Thread.new do
      sleep 0.1
      while Nest.new('ost')[worker.queue].exists; end
      worker.stop
    end
    worker.start
  end

  def exist_queue?(queue)
    Nest.new('ost')[queue].exists
  end

  it 'Job defaults' do
    SingleStepJob.queue.must_be_nil
    SingleStepJob.steps.count.must_equal 1
    SingleStepJob.steps[0].name.must_equal :step_name
    SingleStepJob.steps[0].options.must_equal Hash.new
    SingleStepJob.steps[0].block.class.must_equal Proc
    SingleStepJob.must_respond_to :run
  end

  it 'Process defaults' do
    pid = SingleStepJob.run

    pid.wont_be_nil

    process = Asynchronic::Process.find pid

    process.pipeline.must_equal SingleStepJob
    process.context.must_equal Hash.new
    process.children.count.must_equal 1
    process.children[0].status.must_equal :pending
    process.children[0].output.must_be_nil
  end

  describe 'Execution' do

    it 'One step job' do
      SingleStepJob.queue.must_be_nil
      refute exist_queue? Asynchronic.default_queue

      pid = SingleStepJob.run

      assert exist_queue? Asynchronic.default_queue
      Registry.must_be_empty

      start_and_stop_worker

      process = Asynchronic::Process.find pid
      process.children[0].status.must_equal :finalized
      process.children[0].output.must_equal :single_step_job

      Registry.to_a.must_equal [:single_step_job]
    end

    it 'Two steps with specific queue and context arguments' do
      TwoStepsWithSpecificQueueJob.queue.wont_be_nil
      refute exist_queue? TwoStepsWithSpecificQueueJob.queue

      pid = TwoStepsWithSpecificQueueJob.run value1: 10

      assert exist_queue? TwoStepsWithSpecificQueueJob.queue
      Registry.must_be_empty

      start_and_stop_worker TwoStepsWithSpecificQueueJob.queue

      process = Asynchronic::Process.find pid
      process.context.must_equal value1: 10, value2: 5
      process.children[0].status.must_equal :finalized
      process.children[0].output.must_equal 11
      process.children[1].status.must_equal :finalized
      process.children[1].output.must_equal 55

      Registry.to_a.must_equal [11, 55]
    end

    it 'Steps with different queues (fixed and contextual)' do
      MultipleQueuesJob.queue.must_be_nil
      refute exist_queue? :queue1
      refute exist_queue? :queue2

      pid = MultipleQueuesJob.run dynamic_queue: :queue2

      assert exist_queue? :queue1
      refute exist_queue? :queue2
      Registry.must_be_empty

      start_and_stop_worker :queue1

      process = Asynchronic::Process.find pid
      process.children[0].status.must_equal :finalized
      process.children[1].status.must_equal :pending

      refute exist_queue? :queue1
      assert exist_queue? :queue2
      Registry.to_a.must_equal [:first_queue]

      start_and_stop_worker :queue2

      process = Asynchronic::Process.find pid
      process.children[0].status.must_equal :finalized
      process.children[1].status.must_equal :finalized

      refute exist_queue? :queue1
      refute exist_queue? :queue2
      Registry.to_a.must_equal [:first_queue, :second_queue]
    end

  end

end