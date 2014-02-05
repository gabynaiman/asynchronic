class BasicJob < Asynchronic::Job
  define do
    data[:output] = data[:input] + 1
  end
end


class SequentialJob < Asynchronic::Job

  define do
    define_job Step1
    define_job Step2, dependency: Step1
  end

  class Step1 < Asynchronic::Job
    define do
      data[:partial] = data[:input] * 10
    end
  end

  class Step2 < Asynchronic::Job
    define do
      data[:output] = data[:partial] / 100
    end
  end

end


class GraphJob < Asynchronic::Job
  
  define do
    define_job Sum
    define_job TenPercent, dependency: Sum
    define_job TwentyPercent, dependency: Sum
    define_job Total, dependencies: [TenPercent, TwentyPercent]
  end

  class Sum < Asynchronic::Job
    define do
      data[:sum] = data[:input] + 100
    end
  end

  class TenPercent < Asynchronic::Job
    define do
      data['10%'] = data[:sum] * 0.1
    end
  end

  class TwentyPercent < Asynchronic::Job
    define do
      data['20%'] = data[:sum] * 0.2
    end
  end

  class Total < Asynchronic::Job
    define do
      data[:output] = {'10%' => data['10%'], '20%' => data['20%']}
    end
  end

end


class ParallelJob < Asynchronic::Job
  define do
    data[:times].times do |i|
      define_job Child, local: {index: i}
    end
  end

  class Child < Asynchronic::Job
    define do
      data["key_#{index}"] = data[:input] * index
    end
  end
end


class NestedJob < Asynchronic::Job
  define do
    define_job Level1
  end

  class Level1 < Asynchronic::Job
    define do
      data[:input] += 1
      define_job Level2
    end

    class Level2 < Asynchronic::Job
      define do
        data[:output] = data[:input] ** 2
      end
    end
  end
end


class DependencyAliasJob < Asynchronic::Job
  define do
    define_job Write, local: {text: 'Take'}, alias: :word_1
    define_job Write, local: {text: 'it'}, alias: :word_2, dependency: :word_1
    define_job Write, local: {text: 'easy'}, alias: :word_3, dependency: :word_2
  end

  class Write < Asynchronic::Job
    define do
      data[:text] = "#{data[:text]} #{text}".strip
    end
  end
end


class CustomQueueJob < Asynchronic::Job
  queue :queue_1
  define do
    define_job Reverse, queue: :queue_2
  end

  class Reverse < Asynchronic::Job
    queue :queue_3
    define do
      data[:output] = data[:input].reverse
    end
  end
end


class ExceptionJob < Asynchronic::Job
  define do
    raise 'Error for test'
  end
end


class InnerExceptionJob < Asynchronic::Job
  define do
    define_job ExceptionJob
  end
end
