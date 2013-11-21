require 'ost'
require 'securerandom'
require 'logger'

Dir.glob(File.expand_path('asynchronic/*.rb', File.dirname(__FILE__))).sort.each { |f| require f }

module Asynchronic

  def self.default_queue
    @default_queue ||= :asynchronic
  end

  def self.default_queue=(name)
    @default_queue = name
  end

end