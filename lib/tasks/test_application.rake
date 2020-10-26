# lib/tasks/test_application.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# Test JSON and XML serialization.

# =============================================================================
# Comprehensive tests
# =============================================================================

desc 'Run all tests and all system tests'
task 'test:test+system' => %w(test test:system)

desc 'Run all tests, all serialization tests, and all system tests'
task 'test:all+system' => %w(test:all test:system)

desc 'Run all tests including rendering to JSON and XML'
task 'test:all' => 'test:prepare' do
  TEST_FORMATS = %i[html json xml]
  run_tests
end

# =============================================================================
# Serialization tests
# =============================================================================

desc 'Run controller tests rendering to JSON and XML'
task 'test:serialization' => 'test:serialization:all'

namespace 'test:serialization' do

  desc 'Run controller tests rendering to JSON and XML'
  task all: 'test:prepare' do
    TEST_FORMATS = %i[json xml]
    run_serialization_tests
  end

  desc 'Run controller tests rendering to JSON'
  task json: 'test:prepare' do
    TEST_FORMATS = %i[json]
    run_serialization_tests
  end

  desc 'Run controller tests rendering to XML'
  task xml: 'test:prepare' do
    TEST_FORMATS = %i[xml]
    run_serialization_tests
  end

  # ===========================================================================
  # Support methods
  # ===========================================================================

  def run_serialization_tests
    run_tests('test/controllers')
  end

end

# =============================================================================
# Bookshare API tests
# =============================================================================

desc 'Check code for Bookshare API compliance'
task 'test:bookshare:api' => 'test:bookshare:api:all'

namespace 'test:bookshare:api' do

  desc 'Check implementation of Bookshare API requests and records'
  task all: 'test:prepare' do
    TEST_BOOKSHARE = %i[requests records]
    run_api_tests
  end

  desc 'Check implementation of Bookshare API requests'
  task requests: 'test:prepare' do
    TEST_BOOKSHARE = %i[requests]
    run_api_tests
  end

  desc 'Check implementation of Bookshare API records'
  task records: 'test:prepare' do
    TEST_BOOKSHARE = %i[records]
    run_api_tests
  end

  # ===========================================================================
  # Support methods
  # ===========================================================================

  def run_api_tests
    run_tests('test/system/bookshare_test.rb')
  end

end

# =============================================================================
# Support methods
# =============================================================================

def run_tests(*test_files)
  $: << 'test'
  if test_files.blank?
    Rails::TestUnit::Runner.rake_run
  else
    Rails::TestUnit::Runner.rake_run(test_files.flatten)
  end
end
