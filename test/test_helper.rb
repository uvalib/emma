# test/test_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/boot'
require_relative '../config/environment'

require 'capybara/rails'
require 'rails/test_help'

# If *true* then TestHelper::Debugging methods like #show_url and #show_item
# will produce output on the console, and screenshots will be generated.
#
# Otherwise, no debugging console output is produced and no screenshots will be
# generated.
#
# @type [Boolean]
#
DEBUG_TESTS = true?(ENV_VAR['DEBUG_TESTS'])

# The base URL for relative requests.
#
# @type [String]
#
BASE_URL = 'http://localhost'

# If not testing client-side behavior for system tests, setting this to *false*
# will use Rack::Test rather than Selenium.
#
# NOTE: This is unverified.
#
# @type [Boolean]
#
TESTING_JAVASCRIPT = true
NO_JAVASCRIPT      = !TESTING_JAVASCRIPT

# =============================================================================
# Test helpers
# =============================================================================

public

# Support methods for tests.
#
module TestHelper

  require_submodules(__FILE__)

  include CommandLine
  include Debugging
  include IntegrationTests
  include Samples
  include Utility

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the submodules defined in test/test_helper/*, except for
  # TestHelper::SystemTests, which must be included separately.
  #
  # @param [Module] base
  #
  def self.included(base)
    include_submodules(base, __FILE__) do |name|
      name != :SystemTests
    end
  end

end

# =============================================================================
# Test control values
# =============================================================================

public

# Indicate whether tests should be run in parallel across all available
# processors.
#
# NOTE: Within RubyMine the cumulative time for all tests roughly correlates
#   to the number of processors times the wall clock time for the run.
#   to the wall clock time multiplied by the number of processors.
#
# @type [Boolean]
#
PARALLEL_TESTS = true

# The output format(s) to test.
#
# The current test task may have already set this constant; if not the default
# value set here will be used.
#
# @type [Array<Symbol>]
#
# @see file:lib/tasks/emma_test.rake
#
TEST_FORMATS ||= TestHelper.cli_env_test_formats

# =============================================================================
# Setup system test support classes
# =============================================================================

public

# Augment the base class for test cases (models).
#
class ActiveSupport::TestCase

  include Emma::Common

  include TestHelper

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    extend ActiveRecord::TestFixtures::ClassMethods # for #fixtures
    extend ActiveSupport::Testing::SetupAndTeardown::ClassMethods # for #setup
  end
  # :nocov:

  # Run tests in parallel.
  parallelize if PARALLEL_TESTS
  #parallelize(threshold: 1) if PARALLEL_TESTS

  # Create model instances for all fixtures in defined in test/fixtures/*.yml.
  fixtures :all

  set_fixture_class searches: SearchCall

end

# Make relative paths expand correctly.
#
class ActionDispatch::Integration::Session
  self.default_url_options = { host: URI(BASE_URL).host }
end

# Override supporting test parallelization within RubyMine.
# noinspection RubyResolve
if PARALLEL_TESTS

  require 'minitest/rm_reporter_plugin'

  module Minitest

    cattr_accessor :start_time
    self.start_time = Time.now

    after_run do
      secs = Time.now - start_time
      if (mins = (secs / 60).floor.nonzero?)
        secs -= mins * 60
        delta = "%d MINUTES %.2f SECONDS" % [mins, secs]
      else
        delta = '%.2f SECONDS' % secs
      end
      $stderr.puts "\nTESTS RUN IN #{delta}"
    end

    # Overrides to allow RubyMine to handle parallel tests properly.
    #
    module MinitestExt

      # @private
      SUPERCLASSES = Minitest.const_get(:MINITEST_SUPERCLASSES) rescue %w[
        Minitest::Spec
        Minitest::Test
        ActiveSupport::TestCase
        ActionController::TestCase
        ActionDispatch::IntegrationTest
        ActionMailer::TestCase
        ActionView::TestCase
        ActiveJob::TestCase
        ActiveModel::TestCase
      ].to_set
      private_constant :SUPERCLASSES

      # Override to accommodate the fact that *klass* will be supplied as a
      # Struct instance.
      #
      # @param [Class, Struct, nil] klass
      #
      # @return [String]
      #
      def class_nesting(klass)
        return '' if klass.nil?
        klass_cls = klass.is_a?(Struct) ? klass.name.constantize : klass
        super_cls = klass_cls
        until (name = super_cls.superclass.name).end_with?('TestCase') || SUPERCLASSES.include?(name)
          super_cls = super_cls.superclass
        end
        return '' if super_cls.nil? || (super_cls == klass_cls)
        prefix = "#{super_cls.name}::"
        klass.name.start_with?(prefix) ? '' : prefix
      end

    end

    class << self
      prepend MinitestExt
    end

    # Overrides to allow RubyMine to handle parallel tests properly.
    #
    module RubymineTestDataExt

      def klass=(klass)
        # noinspection RbsMissingTypeSignature
        klass.is_a?(Struct) ? (@klass = klass) : super
      end

    end

    override RubymineTestData => RubymineTestDataExt

  end

end

# =============================================================================
# Gem test setup
# =============================================================================

# Setup system testing.
Capybara.configure do |config|
  config.server = [:puma, { Threads: '0:1' }]
  config.app_host               = BASE_URL
  config.default_host           = BASE_URL
# config.default_max_wait_time  = 5                     # default: 2
# config.enable_aria_label      = true                  # default: false
# config.enable_aria_role       = true                  # default: false
# config.ignore_hidden_elements = false                 # default: true
# config.threadsafe             = true                  # default: false
  config.use_html5_parsing      = true                  # default: false
end

# Setup decorators.
Draper::ViewContext.test_strategy :fast

$stderr.puts "\nDATE #{Date.today}"
