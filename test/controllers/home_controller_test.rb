# test/controllers/home_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'home'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_DSO].freeze
  TEST_READERS = TEST_USERS

  TEST_USER    = TEST_USERS.last

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'home main' do
    run_test(__method__) do
      get home_path
      assert_result :success, OPTIONS.merge(action: 'main')
    end
  end

  test 'home welcome' do
    run_test(__method__) do
      get welcome_path
      assert_result :success, OPTIONS.merge(action: 'welcome')
    end
  end

  test 'home dashboard' do
    run_test(__method__) do
      get sign_in_as_path(id: TEST_USER)
      get dashboard_url
      assert_result :unauthorized, OPTIONS.merge(action: 'dashboard')
    end
  end

end
