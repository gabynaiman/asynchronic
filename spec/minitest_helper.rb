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