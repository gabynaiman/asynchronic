require 'forwardable'
require 'securerandom'
require 'ost'
require 'redic'
require 'broadcaster'
require 'class_config'
require 'transparent_proxy'
require 'logger'
require 'multi_require'
require 'timeout'
require 'socket'

MultiRequire.require_relative_pattern 'asynchronic/**/*.rb'

module Asynchronic

  extend ClassConfig

  attr_config :default_queue, :asynchronic
  attr_config :queue_engine, QueueEngine::InMemory.new
  attr_config :data_store, DataStore::InMemory.new
  attr_config :notifier, Notifier::InMemory.new
  attr_config :logger, Logger.new($stdout)
  attr_config :retry_timeout, 30
  attr_config :garbage_collector_timeout, 30
  attr_config :redis_client, Redic
  attr_config :redis_settings, 'redis://localhost:6379'
  attr_config :redis_data_store_sync_timeout, 0.01
  attr_config :keep_alive_timeout, 1
  attr_config :connection_name, "HOST=#{Socket.gethostname},PID=#{::Process.pid},UUID=#{SecureRandom.uuid}"

  def self.environment
    Environment.new queue_engine, data_store, notifier
  end

  def self.[](pid)
    environment.load_process pid
  end

  def self.processes
    environment.processes
  end

  def self.garbage_collector
    @garbage_collector ||= GarbageCollector.new environment, garbage_collector_timeout
  end

  def self.establish_redis_connection(options={})
    redis_client = options.fetch(:redis_client, Asynchronic.redis_client)
    redis_settings = options.fetch(:redis_settings, Asynchronic.redis_settings)
    redis_client.new redis_settings
  end

  def self.retry_execution(klass, message)
    begin
      result = yield
    rescue Exception => ex
      logger.error(klass) { "Retrying #{message}. ERROR: #{ex.message}" }
      sleep retry_timeout
      retry
    end
    result
  end

end