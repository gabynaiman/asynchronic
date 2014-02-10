require 'coverage_helper'
require 'minitest/autorun'
require 'minitest/great_expectations'
require 'turn'
require 'asynchronic'
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
end