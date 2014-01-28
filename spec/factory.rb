class Factory

  def self.single_job
    Asynchronic::Job.new :simple do |data|
      data['output'] = data['input'] + 1
    end
  end

  def self.sequential_job
    Asynchronic::Job.new :sequential do
      
      job :step1 do |data|
        data[:partial] = data[:input] * 10
      end

      job :step2, dependency: :step1 do |data|
        data[:output] = data[:partial] / 100
      end

    end
  end

  def self.graph_job
    Asynchronic::Job.new :graph do
      
      job :sum do |data|
        data[:sum] = data[:input] + 100
      end

      job '10%', dependency: :sum do |data|
        data['10%'] = data[:sum] * 1.1
      end

      job '20%', dependency: :sum do |data|
        data['20%'] = data[:sum] * 1.2
      end

      job :totals, dependencies: ['10%', '20%'] do |data|
        data[:output] = {'10%' => data['10%'], '20%' => data['20%']}
      end

    end
  end

  def self.parallel_job
    Asynchronic::Job.new :parallel do |data|
      data[:times].times do |i|
        job "time_#{i}" do |d|
          d["time_#{i}"] = d[:input] * i
        end
      end
    end
  end

end