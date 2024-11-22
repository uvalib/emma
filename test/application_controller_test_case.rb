# test/application_controller_test_case.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

# Common base for controller tests, which check the HTTP response status of
# endpoints for users of differing roles.
#
class ApplicationControllerTestCase < ActionDispatch::IntegrationTest

  include Devise::Test::IntegrationHelpers
  include TestHelper
  include TestHelper::Debugging::Trace
  extend  TestHelper::Utility

end
