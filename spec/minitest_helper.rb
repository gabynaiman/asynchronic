require 'coverage_helper'
require 'asynchronic'
require 'minitest/autorun'
require 'minitest/colorin'
require 'minitest/great_expectations'
require 'jobs'
require 'expectations'

class Module
  include Minitest::Spec::DSL
end

Asynchronic.logger.level = Logger::FATAL

class Minitest::Spec
  before do
    Asynchronic.restore_default_configuration
  end

  after do
    Asynchronic::DataStore::Redis.new.clear
    Asynchronic::QueueEngine::Ost.new.clear
  end
end

module Asynchronic::DataStore::Helper
  def dump
    puts 'DataStore:'
    each do |k,v|
      puts "#{k}: #{v}"
    end
  end
end