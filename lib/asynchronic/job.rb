module Asynchronic
  class Job

    attr_reader :id
    attr_reader :name
    attr_reader :queue
    attr_reader :parent
    attr_reader :dependencies
    attr_reader :local

    def initialize(options={})
      @id = SecureRandom.uuid
      @name = options.key?(:alias) ? options[:alias].to_s : self.class.to_s
      @queue = options[:queue] || self.class.queue
      @parent = options[:parent]
      @dependencies = Array(options[:dependencies] || options[:dependency]).map(&:to_s)
      @local = options[:local] || {}

      raise 'Cant have dependencies without parent job' if dependencies.any? && parent.nil?
    end

    def lookup
      DataStore::Lookup.new self
    end

    def self.queue(queue=nil)
      queue ? @queue = queue : @queue
    end

    def self.implementation
      @implementation
    end

    private

    def self.define(&block)
      @implementation = block
    end

  end
end