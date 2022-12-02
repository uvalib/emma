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

    task default: 'test:prepare' do
      run_interactive_tests(except: "#{SYSTEM_DIR}/bookshare_test.rb")
    end

    # =======================================================================
    # Support methods
    # =======================================================================

    SYSTEM_DIR = 'test/system'

    def run_interactive_tests(except: [])
      files = Dir.glob("#{SYSTEM_DIR}/**/*_test.rb") - Array.wrap(except)
      run_tests(*files)
    end

  end

  # ===========================================================================
  # Data tests
  # ===========================================================================

  desc 'Run data tests'
  task data: 'emma:test:data:all'

  namespace :data do

    task all: :default

    task default: 'test:prepare' do
      run_data_tests
    end

    # =======================================================================
    # Support methods
    # =======================================================================

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
    task all: 'test:prepare' do
      set_test_formats(:json, :xml)
      run_serialization_tests
    end

    desc 'Run controller tests rendering to JSON'
    task json: 'test:prepare' do
      set_test_formats(:json)
      run_serialization_tests
    end

    desc 'Run controller tests rendering to XML'
    task xml: 'test:prepare' do
      set_test_formats(:xml)
      run_serialization_tests
    end

    desc 'Run controller tests rendering to HTML'
    task html: 'test:prepare' do
      set_test_formats(:html)
      run_serialization_tests
    end

    desc 'Run controller tests rendering to HTML, JSON, and XML'
    task complete: 'test:prepare' do
      set_test_formats(:html, :json, :xml)
      run_serialization_tests
    end

    task default: 'test:prepare' do
      set_test_formats
      run_serialization_tests
    end

    # =======================================================================
    # Support methods
    # =======================================================================

    def set_test_formats(*values)
      $LOAD_PATH << 'test' unless $LOAD_PATH.include?('test')
      require 'test_helper' unless defined?(TestHelper)
      values = values.flatten.presence || TestHelper.cli_env_test_formats
      silence_warnings { Object.const_set(:TEST_FORMATS, values) }
    end

    def run_serialization_tests
      run_tests('test/controllers')
    end

  end

  # ===========================================================================
  # Bookshare API tests
  # ===========================================================================

  desc 'Check code for Bookshare API compliance'
  task bookshare_api: 'emma:test:bookshare_api:default'

  namespace :bookshare_api do

    desc 'Check implementation of Bookshare API requests and records'
    task all: :complete

    desc 'Check Bookshare API documentation'
    task methods: 'test:prepare' do
      set_test_bookshare(:methods)
      run_bs_api_tests
    end

    desc 'Check implementation of Bookshare API requests'
    task requests: 'test:prepare' do
      set_test_bookshare(:requests)
      run_bs_api_tests
    end

    desc 'Check implementation of Bookshare API records'
    task records: 'test:prepare' do
      set_test_bookshare(:records)
      run_bs_api_tests
    end

    task complete: 'test:prepare' do
      set_test_bookshare(:methods, :requests, :records)
      run_bs_api_tests
    end

    task default: 'test:prepare' do
      set_test_bookshare
      run_bs_api_tests
    end

    # =======================================================================
    # Support methods
    # =======================================================================

    def set_test_bookshare(*values)
      $LOAD_PATH << 'test' unless $LOAD_PATH.include?('test')
      require 'test_helper' unless defined?(TestHelper)
      values = values.flatten.presence || TestHelper.cli_env_test_bookshare
      silence_warnings { Object.const_set(:TEST_BOOKSHARE, values) }
    end

    def run_bs_api_tests
      run_tests('test/system/bookshare_test.rb')
    end

  end

  # ===========================================================================
  # Support tasks
  # ===========================================================================

  desc 'Get local test user data'
  task users: :prerequisites do
    # noinspection SqlResolve
    rel = User.where('access_token IS NOT NULL')
    # noinspection RailsParamDefResolve
    rel.pluck(:email, :access_token).map do |user, token|
      puts "#{user}\t#{token}"
    end
  end

  # desc 'Required prerequisites for tasks in this namespace.'
  task prerequisites: %w(environment db:load_config)

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
    test_files = test_files.flatten.presence || %w(test/**/*_test.rb)
    Rails::TestUnit::Runner.rake_run(test_files)
  end

end
