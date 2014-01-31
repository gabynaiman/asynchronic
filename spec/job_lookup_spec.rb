require 'minitest_helper'

describe Asynchronic::Job::Lookup do

  describe 'One level' do

    let(:specification) { Asynchronic::Specification.new :test }
    let(:lookup) { Asynchronic::Job::Lookup.new specification }

    it 'Job' do
      lookup.job.must_equal "asynchronic:job:#{specification.id}"
    end

    it 'Status' do
      lookup.status.must_equal "asynchronic:job:#{specification.id}:status"
    end

    it 'Data' do
      lookup.data.must_equal "asynchronic:job:#{specification.id}:data"
    end

    it 'Jobs' do
      lookup.jobs.must_equal "asynchronic:job:#{specification.id}:jobs"
    end

    it 'Error' do
      lookup.error.must_equal "asynchronic:job:#{specification.id}:error"
    end

  end

  describe 'Two levels' do

    let(:parent) { "asynchronic:job:#{SecureRandom.uuid}" }
    let(:specification) { Asynchronic::Specification.new :test, parent: parent }
    let(:lookup) { Asynchronic::Job::Lookup.new specification }

    it 'Job' do
      lookup.job.must_equal "#{parent}:jobs:#{specification.id}"
    end

    it 'Status' do
      lookup.status.must_equal "#{parent}:jobs:#{specification.id}:status"
    end

    it 'Data' do
      lookup.data.must_equal "#{parent}:jobs:#{specification.id}:data"
    end

    it 'Jobs' do
      lookup.jobs.must_equal "#{parent}:jobs:#{specification.id}:jobs"
    end

    it 'Error' do
      lookup.error.must_equal "#{parent}:jobs:#{specification.id}:error"
    end

  end

end