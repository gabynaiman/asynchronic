require 'mock_redis'

class MockRedis
  def self.current
    @current ||= new
  end
end

Object.send :remove_const, :Redis

Redis = MockRedis