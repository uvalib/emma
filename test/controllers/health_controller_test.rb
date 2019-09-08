# test/controllers/health_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class HealthControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER     = 'health'
  OPTIONS        = { controller: CONTROLLER, media_type: :json }.freeze

  TEST_USERS     = [ANONYMOUS].freeze
  TEST_READERS   = TEST_USERS

  TEST_SUBSYSTEM = 'bookshare'

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'version' do
    run_test(__method__) do
      get version_path
      assert_result :success, OPTIONS.merge(action: 'version')
    end
  end

  test 'health version' do
    run_test(__method__) do
      get version_health_path
      assert_result :success, OPTIONS.merge(action: 'version')
    end
  end

  test 'healthcheck' do
    run_test(__method__) do
      get healthcheck_path
      assert_result :success, OPTIONS.merge(action: 'check')
    end
  end

  test 'health check - all subsystem statuses' do
    run_test(__method__) do
      get check_health_path
      assert_result :success, OPTIONS.merge(action: 'check')
    end
  end

  test 'health check - single subsystem status' do
    run_test(__method__) do
      get check_subsystem_health_path(subsystem: TEST_SUBSYSTEM)
      assert_result :success, OPTIONS.merge(action: 'check')
    end
  end

end
