require 'minitest_helper'
require 'jobs'

describe 'Integration' do

  before do
    JobLogger.clean
  end

  it 'Basic Job' do
    pid = BasicJob.run

    JobLogger.history.must_be :empty?
    process = Asynchronic::Process.find pid

    puts process.methods
  end

end