require 'coverage_helper'
require 'asynchronic'
require 'minitest/autorun'
require 'minitest/colorin'
require 'minitest/great_expectations'
require 'minitest/stub_any_instance'
require 'jobs'
require 'expectations'
require 'timeout'
require 'pry-nav'

require_relative 'data_store/data_store_examples'
require_relative 'data_store/lazy_value_examples'
require_relative 'process/life_cycle_examples'
require_relative 'queue_engine/queue_engine_examples'
require_relative 'worker/worker_examples'

Asynchronic.logger.level = Logger::FATAL

class Minitest::Spec
  before do
    Asynchronic.restore_default_configuration
    Asynchronic.default_queue = :asynchronic_test
  end
end