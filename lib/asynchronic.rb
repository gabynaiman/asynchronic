require 'ost'
require 'securerandom'
require 'base64'
require 'logger'
require 'fileutils'

Dir.glob(File.expand_path('asynchronic/*.rb', File.dirname(__FILE__))).sort.each { |f| require f }

module Asynchronic

  def self.default_queue
    @default_queue ||= :asynchronic
  end

  def self.default_queue=(name)
    @default_queue = name
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.connect_redis(options)
    Ost.connect options
    @redis = Redis.new options
  end

  def self.redis
    @redis ||= Redis.current
  end

  def self.archiving_path
    @archiving_path ||= File.join(Dir.home, '.asynchronic', 'data')
  end
  
  def self.archiving_path=(path)
    @archiving_path = path
  end

  def self.archiving_file(name)
    File.join archiving_path, "#{name}.bin"
  end

end