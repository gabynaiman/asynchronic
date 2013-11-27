require 'coverage_helper'
require 'minitest/autorun'
require 'turn'
require 'asynchronic'
require 'redis_helper'

Turn.config do |c|
  c.format = :pretty
  c.natural = true
end

class MiniTest::Spec
  
  before do
    Redis.current.flushdb
  end

  def redis
    Redis.current
  end

end