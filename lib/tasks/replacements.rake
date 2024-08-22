# lib/tasks/replacements.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# Overrides of $GEM_HOME/gems/railties-*/lib/rails/test_unit/testing.rake task
# definitions.

%w[all system models controllers].each do |name|
  Rake::Task["test:#{name}"].clear
end

namespace :test do

  desc 'Run all EMMA tests'
  task all: %w[system models controllers+serialization]

  desc ['Run all EMMA tests', '(except serialization)']
  task 'all-serialization': %w[system models controllers]

  desc 'Run all EMMA system tests'
  task system: 'emma:test:interactive:default'

  desc 'Run all EMMA model tests'
  task models: 'emma:test:data:default'

  desc 'Run all EMMA controller tests'
  task controllers: 'emma:test:serialization:default'

  desc 'Run all EMMA controller tests including serialization'
  task 'controllers+serialization': 'emma:test:serialization:complete'

end
