class Factory

  def self.single_job(data_store, data)
    Asynchronic::Job.new :simple, data_store: data_store, data: data do
      data[:output] = data[:input] + 1
    end
  end

  def self.sequential_job(data_store, data)
    Asynchronic::Job.new :sequential, data_store: data_store, data: data do
      
      job :step1 do
        data[:partial] = data[:input] * 10
      end

      job :step2, dependency: :step1 do
        data[:output] = data[:partial] / 100
      end

    end
  end

  def self.graph_job(data_store, data)
    Asynchronic::Job.new :graph, data_store: data_store, data: data do
      
      job :sum do
        data[:sum] = data[:input] + 100
      end

      job '10%', dependency: :sum do
        data['10%'] = data[:sum] * 1.1
      end

      job '20%', dependency: :sum do
        data['20%'] = data[:sum] * 1.2
      end

      job :totals, dependencies: ['10%', '20%'] do
        data[:output] = {'10%' => data['10%'], '20%' => data['20%']}
      end

    end
  end

  def self.parallel_job(data_store, data)
    Asynchronic::Job.new :parallel, data_store: data_store, data: data do
      data[:times].times do |i|
        job "time_#{i}" do
          data["time_#{i}"] = data[:input] * i
        end
      end
    end
  end

end