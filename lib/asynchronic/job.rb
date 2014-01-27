module Asynchronic
  class Job

    extend Forwardable

    def_delegators :data, :[], :[]=

    attr_reader :id
    attr_reader :name

    def initialize(name, options={})
      @id = SecureRandom.uuid
      @name = name
      @data_store = options[:data_store]
      data.merge! options.fetch(:data, {})
    end

    def enqueue(queue)
      queue.push id
    end

    private

    def data
      @data_store[:jobs][id]
    end
  
  end
end