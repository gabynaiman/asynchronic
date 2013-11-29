require 'coverage_helper'
require 'minitest/autorun'
require 'turn'
require 'asynchronic'

Turn.config do |c|
  c.format = :pretty
  c.natural = true
end

logger = Logger.new($stdout)
logger.level = Logger::DEBUG
Asynchronic.logger = logger

Asynchronic.connect_redis host: 'localhost', port: 6379

Asynchronic.default_queue = 'asynchronic_test'

Asynchronic.archiving_path = File.expand_path('../tmp', File.dirname(__FILE__))

class MiniTest::Spec
  
  before do
    Redis.current.flushdb
  end

  def redis
    Redis.current
  end

end