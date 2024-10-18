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
DEBUG_TESTS = true

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

  # Create model instances for all fixtures in defined in test/fixtures/*.yml.
  fixtures :all

  set_fixture_class searches: SearchCall

end

# Augment the base class for integration test cases (controllers).
#
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include TestHelper
  include TestHelper::Debugging::Trace
  extend  TestHelper::Utility
end

# Make relative paths expand correctly.
#
class ActionDispatch::Integration::Session
  self.default_url_options = { host: URI(BASE_URL).host }
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
