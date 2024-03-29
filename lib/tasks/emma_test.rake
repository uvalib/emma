# lib/tasks/emma_test.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA regression tests, including JSON/XML serialization tests.

namespace 'emma:test' do

  # ===========================================================================
  # Interactive tests
  # ===========================================================================

  desc 'Run interactive tests'
  task interactive: 'emma:test:interactive:all'

  namespace :interactive do

    task all: :default

    task default: :prerequisites do
      run_interactive_tests
    end

    # =========================================================================
    # Support methods
    # =========================================================================

    def run_interactive_tests
      run_tests('test/system')
    end

  end

  # ===========================================================================
  # Data tests
  # ===========================================================================

  desc 'Run data tests'
  task data: 'emma:test:data:all'

  namespace :data do

    task all: :default

    task default: :prerequisites do
      run_data_tests
    end

    # =========================================================================
    # Support methods
    # =========================================================================

    def run_data_tests
      run_tests('test/models')
    end

  end

  # ===========================================================================
  # Serialization tests
  # ===========================================================================

  desc 'Run controller tests rendering to non-HTML formats'
  task serialization: 'emma:test:serialization:all'

  namespace :serialization do

    desc 'Run controller tests rendering to JSON and XML'
    task all: :prerequisites do
      run_serialization_tests(:json, :xml)
    end

    desc 'Run controller tests rendering to JSON'
    task json: :prerequisites do
      run_serialization_tests(:json)
    end

    desc 'Run controller tests rendering to XML'
    task xml: :prerequisites do
      run_serialization_tests(:xml)
    end

    desc 'Run controller tests rendering to HTML'
    task html: :prerequisites do
      run_serialization_tests(:html)
    end

    desc 'Run controller tests rendering to HTML, JSON, and XML'
    task complete: :prerequisites do
      run_serialization_tests(:html, :json, :xml)
    end

    task default: :prerequisites do
      run_serialization_tests
    end

    # =========================================================================
    # Support methods
    # =========================================================================

    def run_serialization_tests(*formats)
      $LOAD_PATH << 'test'  unless $LOAD_PATH.include?('test')
      require 'test_helper' unless defined?(TestHelper)
      formats = formats.flatten.presence || TestHelper.cli_env_test_formats
      silence_warnings { Object.const_set(:TEST_FORMATS, formats) }
      run_tests('test/controllers')
    end

  end

  # ===========================================================================
  # Support tasks
  # ===========================================================================

  # desc 'Required prerequisites for tasks in this namespace.'
  task prerequisites: %w[test:prepare]

  # ===========================================================================
  # Support methods
  # ===========================================================================

  public

  # Run the specified tests.
  #
  # @param [Array] test_files       Default: "test/**/*_test.rb"
  #
  # @return [void]
  #
  def run_tests(*test_files)
    $LOAD_PATH << 'test' unless $LOAD_PATH.include?('test')
    test_files = test_files.flatten.presence || %w[test/**/*_test.rb]
    Rails::TestUnit::Runner.run(test_files)
  end

end
