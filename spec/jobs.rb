class BasicJob < Asynchronic::Job
  def call
    params[:input] + 1
  end
end


class SequentialJob < Asynchronic::Job

  def call
    async Step1, input: params[:input]
    
    async Step2, dependency: Step1, 
                 input: params[:input]

    nil
  end

  class Step1 < Asynchronic::Job
    def call
      params[:input] * 10
    end
  end

  class Step2 < Asynchronic::Job
    def call
      params[:input] / 10
    end
  end

end


class GraphJob < Asynchronic::Job
  
  def call
    async Sum, input: params[:input]

    async TenPercent, input: result(Sum)

    async TwentyPercent, input: result(Sum)

    async Total, '10%' => result(TenPercent),
                 '20%' => result(TwentyPercent)

    result Total
  end

  class Sum < Asynchronic::Job
    def call
      params[:input] + 100
    end
  end

  class TenPercent < Asynchronic::Job
    def call
      params[:input] * 0.1
    end
  end

  class TwentyPercent < Asynchronic::Job
    def call
      params[:input] * 0.2
    end
  end

  class Total < Asynchronic::Job
    def call
      {'10%' => params['10%'], '20%' => params['20%']}
    end
  end

end


class ParallelJob < Asynchronic::Job
  def call
    params[:times].times do |i|
      async Child, input: params[:input], index: i
    end
  end

  class Child < Asynchronic::Job
    def call
      params[:input] * params[:index]
    end
  end
end


class NestedJob < Asynchronic::Job
  def call
    async Level1, input: params[:input]
    result Level1
  end

  class Level1 < Asynchronic::Job
    def call
      async Level2, input: params[:input] + 1
      result Level2
    end

    class Level2 < Asynchronic::Job
      def call
        params[:input] ** 2
      end
    end
  end
end


class AliasJob < Asynchronic::Job
  def call
    async Write, alias: :word_1,
                 text: 'Take'
    
    async Write, alias: :word_2, 
                 text: 'it', 
                 prefix: result(:word_1)
    
    async Write, alias: :word_3, 
                 text: 'easy', 
                 prefix: result(:word_2)

    result :word_3
  end

  class Write < Asynchronic::Job
    def call
      [params[:prefix], params[:text]].compact.join(' ')
    end
  end
end


class CustomQueueJob < Asynchronic::Job
  queue :queue_1
  def call
    async Reverse, queue: :queue_2, input: params[:input]
    result Reverse
  end

  class Reverse < Asynchronic::Job
    queue :queue_3
    def call
      params[:input].reverse
    end
  end
end


class ExceptionJob < Asynchronic::Job
  def call
    raise 'Error for test'
  end
end


class InnerExceptionJob < Asynchronic::Job
  def call
    async ExceptionJob
  end
end


class WorkerJob < Asynchronic::Job
  def call
  end
end


class ForwardReferenceJob < Asynchronic::Job
  def call
    async BuildReferenceJob
    async SendReferenceJob, number: result(BuildReferenceJob)
    result SendReferenceJob
  end

  class BuildReferenceJob < Asynchronic::Job
    def call
      1
    end
  end

  class SendReferenceJob < Asynchronic::Job
    def call
      async UseReferenceJob, number: params[:number]
      result UseReferenceJob
    end
  end

  class UseReferenceJob < Asynchronic::Job
    def call
      params[:number] + 1
    end
  end
end


class WithRetriesJob < Asynchronic::Job
  def call
    @counter = 0
    retry_when [RuntimeError] do
      @counter += 1
      raise 'Counter < 3' if @counter < 3
      @counter
    end
  end
end


class NestedJobWithDifferentsQueuesJob < Asynchronic::Job
  def call
    async Level1, input: params[:input]
    result Level1
  end

  class Level1 < Asynchronic::Job
    queue :other_queue
    def call
      async Level2, input: params[:input] + 1
      result Level2
    end

    class Level2 < Asynchronic::Job
      def call
        params[:input] + 1
      end
    end
  end
end


class DataJob < Asynchronic::Job
  def call
    set :text, "Input was #{params[:input]}"
    set :value, params[:input]
    nil
  end
end

class NestedJobWithErrorInParent< Asynchronic::Job

  def call
    async Child_1
    raise "Error in parent"
    nil
  end

  class Child_1 < Asynchronic::Job
    def call
      nil
    end
  end

end


class NestedJobWithErrorInChild < Asynchronic::Job

  def call
    async Child_1
    async Child_2
    async Child_3
    nil
  end

  class Child_1 < Asynchronic::Job
    def call
      async Child_1_1
      async Child_1_2
      nil
    end

    class Child_1_1 < Asynchronic::Job
      def call
        nil
      end
    end

    class Child_1_2 < Asynchronic::Job
      def call
        nil
      end
    end
  end

  class Child_2 < Asynchronic::Job
    def call
      async Child_2_1
      async Child_2_2
      async Child_2_3
      nil
    end

    class Child_2_1 < Asynchronic::Job
      def call
        nil
      end
    end

    class Child_2_2 < Asynchronic::Job
      def call
        raise "Error in Child_2_2"
      end
    end

    class Child_2_3 < Asynchronic::Job
      def call
        nil
      end
    end
  end

  class Child_3 < Asynchronic::Job
    def call
      async Child_3_1
      nil
    end

    class Child_3_1 < Asynchronic::Job
      def call
        nil
      end
    end
  end
end