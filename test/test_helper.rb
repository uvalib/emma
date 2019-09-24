# test/test_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'rails/test_help'
require 'webdrivers'

# The output format(s) to test.
#
# @type [Array<Symbol>]
#
# @see lib/tasks/test_serialization.rb
#
TEST_FORMATS ||= %i[html]

# Support methods for tests.
#
module TestHelper

  TESTING_HTML = TEST_FORMATS.include?(:html)
  TESTING_JSON = TEST_FORMATS.include?(:json)
  TESTING_XML  = TEST_FORMATS.include?(:xml)

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
  # @return [Array<Module>]           @see #include_submodules
  #
  def self.included(base)
    include_submodules(base, __FILE__) do |name|
      next if name == :SystemTests
    end
  end

end

# Augment the base class for test cases.
class ActiveSupport::TestCase

  include GenericHelper
  include TestHelper

  # Create model instances for all fixtures in defined in test/fixtures/*.yml.
  fixtures :all

end

# Augment the base class for integration test cases.
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include TestHelper::Debugging::Trace
end

# Make relative paths expand correctly.
class ActionDispatch::Integration::Session
  self.default_url_options = { host: URI(TestHelper::BASE_URL).host }
end

# Set up system testing.
Capybara.configure do |config|
  config.app_host = TestHelper::BASE_URL  # TODO: needed?
  config.default_max_wait_time = 60
  # config.allow_gumbo = true             # TODO: ??? (default is false)
  # config.enable_aria_label = true       # TODO: ??? (default is false)
  # config.ignore_hidden_elements = false # TODO: ??? (default is true)
end
