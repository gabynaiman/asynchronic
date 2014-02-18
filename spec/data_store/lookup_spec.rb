require 'minitest_helper'

describe Asynchronic::DataStore::Lookup do

  describe 'One level' do

    let(:job) { Asynchronic::Job.new }
    let(:lookup) { Asynchronic::DataStore::Lookup.new job }

    it 'Id' do
      lookup.id.must_equal "job:#{job.id}"
    end

    it 'Status' do
      lookup.status.must_equal "job:#{job.id}:status"
    end

    it 'Data' do
      lookup.data.must_equal "job:#{job.id}:data"
    end

    it 'Jobs' do
      lookup.jobs.must_equal "job:#{job.id}:jobs"
    end

    it 'Error' do
      lookup.error.must_equal "job:#{job.id}:error"
    end

    it 'Created At' do
      lookup.created_at.must_equal "job:#{job.id}:created_at"
    end

    it 'Queued At' do
      lookup.queued_at.must_equal "job:#{job.id}:queued_at"
    end

    it 'Started At' do
      lookup.started_at.must_equal "job:#{job.id}:started_at"
    end

    it 'Finalized At' do
      lookup.finalized_at.must_equal "job:#{job.id}:finalized_at"
    end

  end

  describe 'Two levels' do

    let(:parent) { "job:#{SecureRandom.uuid}" }
    let(:job) { Asynchronic::Job.new parent: parent }
    let(:lookup) { Asynchronic::DataStore::Lookup.new job }

    it 'Id' do
      lookup.id.must_equal "#{parent}:jobs:#{job.id}"
    end

    it 'Status' do
      lookup.status.must_equal "#{parent}:jobs:#{job.id}:status"
    end

    it 'Data' do
      lookup.data.must_equal "#{parent}:jobs:#{job.id}:data"
    end

    it 'Jobs' do
      lookup.jobs.must_equal "#{parent}:jobs:#{job.id}:jobs"
    end

    it 'Error' do
      lookup.error.must_equal "#{parent}:jobs:#{job.id}:error"
    end

    it 'Created At' do
      lookup.created_at.must_equal "#{parent}:jobs:#{job.id}:created_at"
    end

    it 'Queued At' do
      lookup.queued_at.must_equal "#{parent}:jobs:#{job.id}:queued_at"
    end

    it 'Started At' do
      lookup.started_at.must_equal "#{parent}:jobs:#{job.id}:started_at"
    end

    it 'Finalized At' do
      lookup.finalized_at.must_equal "#{parent}:jobs:#{job.id}:finalized_at"
    end

  end

end