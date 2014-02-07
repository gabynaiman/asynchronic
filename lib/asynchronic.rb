require 'forwardable'
require 'securerandom'
require 'redis'
require 'ost'
require 'class_config'
require 'logger'

Dir.glob(File.expand_path('asynchronic/**/*.rb', File.dirname(__FILE__))).sort.each { |f| require f }

module Asynchronic

  extend ClassConfig

  attr_config :default_queue, :asynchronic
  attr_config :queue_engine, QueueEngine::InMemory.new
  attr_config :data_store, DataStore::InMemory.new
  attr_config :logger, Logger.new($stdout)

  def self.environment
    Environment.new queue_engine, data_store
  end

  def self.enqueue(job_class, data={})
    process = environment.build_process job_class
    process.enqueue data
  end

end