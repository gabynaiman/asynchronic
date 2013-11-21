require 'coverage_helper'
require 'minitest/autorun'
require 'turn'
require 'asynchronic'

Turn.config do |c|
  c.format = :pretty
  c.natural = true
end