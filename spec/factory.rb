class Factory

  def self.single_job(context)
    context.define_job :simple do |data|
      data[:output] = data[:input] + 1
    end
  end

  def self.sequential_job(context)
    context.define_job :sequential do
      
      define_job :step1 do |data|
        data[:partial] = data[:input] * 10
      end

      define_job :step2, dependency: :step1 do |data|
        data[:output] = data[:partial] / 100
      end

    end
  end

  def self.graph_job(context)
    context.define_job :graph do
      
      define_job :sum do |data|
        data[:sum] = data[:input] + 100
      end

      define_job '10%', dependency: :sum do |data|
        data['10%'] = data[:sum] * 0.1
      end

      define_job '20%', dependency: :sum do |data|
        data['20%'] = data[:sum] * 0.2
      end

      define_job :totals, dependencies: ['10%', '20%'] do |data|
        data[:output] = {'10%' => data['10%'], '20%' => data['20%']}
      end

    end
  end

  def self.parallel_job(context)
    context.define_job :parallel do |data|
      data[:times].times do |i|
        define_job "job_#{i}" do |d|
          d["key_#{i}"] = d[:input] * i
        end
      end
    end
  end

  def self.exception_job(context)
    context.define_job :exception do
      raise 'Error for test'
    end
  end

end