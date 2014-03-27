require 'coverage_helper'
require 'asynchronic'
require 'minitest/autorun'
require 'minitest/great_expectations'
require 'turn'
require 'jobs'
require 'expectations'

Turn.config do |c|
  c.format = :pretty
  c.natural = true
end

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