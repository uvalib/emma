# test/test_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'rails/test_help'
require 'webdrivers'

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
# @see file:lib/tasks/test_application.rake
#
TEST_FORMATS ||= %i[html]

TESTING_HTML = TEST_FORMATS.include?(:html)
TESTING_JSON = TEST_FORMATS.include?(:json)
TESTING_XML  = TEST_FORMATS.include?(:xml)

# Bookshare API aspects to test.
#
# The current test task may have already set this constant; if not the default
# value set here will be used.
#
# @type [Array<Symbol>]
#
# @see file:lib/tasks/test_application.rake
#
# == Usage Notes
# No Bookshare-specific tests are run unless specified by the test task.
#
TEST_BOOKSHARE ||= []

TESTING_BOOKSHARE_API = TEST_BOOKSHARE.present?
TESTING_API_REQUESTS  = TEST_BOOKSHARE.include?(:requests)
TESTING_API_RECORDS   = TEST_BOOKSHARE.include?(:records)

# =============================================================================
# Test helpers
# =============================================================================

public

# Support methods for tests.
#
module TestHelper

  # The base URL for relative requests.
  #
  # @type [String]
  #
  BASE_URL = 'http://localhost'

  # If *true* then #show and #show_reflections will produce output on the
  # console.
  #
  # @type [Boolean]
  #
  DEBUG_TESTS = true

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Include the submodules defined in test/test_helper/*, except for
  # TestHelper::SystemTests, which must be included separately.
  #
  # @param [Module] base
  #
  def self.included(base)
    include_submodules(base, __FILE__) do |name|
      next if name == :SystemTests
    end
  end

end

# =============================================================================
# Setup system test support classes
# =============================================================================

public

# Augment the base class for test cases.
#
class ActiveSupport::TestCase

  include Emma::Common
  include TestHelper

  # Create model instances for all fixtures in defined in test/fixtures/*.yml.
  fixtures :all

  set_fixture_class searches: SearchCall

end

# Augment the base class for integration test cases.
#
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include TestHelper::Debugging::Trace
end

# Make relative paths expand correctly.
#
class ActionDispatch::Integration::Session
  self.default_url_options = { host: URI(TestHelper::BASE_URL).host }
end

# Set up system testing.
#
Capybara.configure do |config|
  config.app_host              = TestHelper::BASE_URL
  config.default_host          = TestHelper::BASE_URL
  config.default_max_wait_time = 60
  # config.allow_gumbo = true             # TODO: ??? (default is false)
  # config.enable_aria_label = true       # TODO: ??? (default is false)
  # config.ignore_hidden_elements = false # TODO: ??? (default is true)
end
