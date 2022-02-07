# frozen_string_literal: true

require "rubocop/rake_task"
require "yard"

begin
  # @see https://relishapp.com/rspec/rspec-core/docs/command-line/rake-task
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # Looks like RSpec is unavailable in the current environment
end

RuboCop::RakeTask.new do |task|
  task.requires << "rubocop-md"
  task.requires << "rubocop-performance"
  task.requires << "rubocop-rake"
  task.requires << "rubocop-rspec"
  task.requires << "rubocop-thread_safety"
end

YARD::Rake::YardocTask.new

Dir["tasks/**/*.rake"].each { |t| load t }

task default: %i[
  spec
  rubocop:auto_correct
  yard
]
