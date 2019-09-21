# lib/tasks/test_serialization.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Test JSON and XML serialization.

desc 'Run all tests and all system tests'
task 'test:all+system' => %w(test:all test:system)

desc 'Run all tests including rendering to JSON and XML'
task 'test:all' => 'test:prepare' do
  TEST_FORMATS = %i[html json xml]
  $: << 'test'
  Rails::TestUnit::Runner.rake_run
end

desc 'Run controller tests rendering to JSON and XML'
task 'test:serialization' => 'test:prepare' do
  TEST_FORMATS = %i[json xml]
  $: << 'test'
  Rails::TestUnit::Runner.rake_run(%w(test/controllers))
end

desc 'Run controller tests rendering to JSON'
task 'test:serialization:json' => 'test:prepare' do
  TEST_FORMATS = %i[json]
  $: << 'test'
  Rails::TestUnit::Runner.rake_run(%w(test/controllers))
end

desc 'Run controller tests rendering to XML'
task 'test:serialization:xml' => 'test:prepare' do
  TEST_FORMATS = %i[xml]
  $: << 'test'
  Rails::TestUnit::Runner.rake_run(%w(test/controllers))
end
