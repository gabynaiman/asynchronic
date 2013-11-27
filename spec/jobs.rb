class JobLogger
  def self.write(obj)
    history << obj
  end

  def self.clean
    @history = []
  end

  def self.history
    @history ||= []
  end
end

class BasicJob
  extend Asynchronic::Pipeline

  step :first do
    Log.write :first
  end

  step :second do
    Log.write :first
  end
end