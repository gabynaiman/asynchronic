require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:spec) do |t|
  t.libs << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = false
  t.warning = false
end

task :console do
  require 'pry'
  require 'asynchronic'
  ARGV.clear
  Pry.start
end

task default: :spec