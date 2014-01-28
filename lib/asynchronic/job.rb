module Asynchronic
  class Job

    attr_reader :id
    attr_reader :name

    def initialize(name, &block)
      @id = SecureRandom.uuid
      @name = name
      @block = block
    end

    def execute(context)
      @block.call context
    end

  end
end