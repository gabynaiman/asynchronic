module Asynchronic
  class Specification

    attr_reader :id
    attr_reader :name
    attr_reader :queue
    attr_reader :parent
    attr_reader :dependencies
    attr_reader :block

    def initialize(name, options={}, &block)
      @id = SecureRandom.uuid
      @name = name
      @queue = options[:queue]
      @parent = options[:parent]
      @dependencies = Array(options[:dependencies] || options[:dependency])
      @block = block

      raise 'Cant have dependencies without parent job' if dependencies.any? && parent.nil?
    end

  end
end