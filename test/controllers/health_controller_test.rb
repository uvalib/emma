# test/controllers/health_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class HealthControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER     = 'health'
  OPTIONS        = { controller: CONTROLLER, format: :json }.freeze

  TEST_USERS     = [ANONYMOUS].freeze
  TEST_READERS   = TEST_USERS

  TEST_SUBSYSTEM = 'bookshare'

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  if TESTING_HTML

    test 'version' do
      url     = version_url
      options = OPTIONS.merge(action: 'version')
      run_test(__method__) do
        get url
        assert_result :success, options
      end
    end

    test 'health version' do
      url     = version_health_url
      options = OPTIONS.merge(action: 'version')
      run_test(__method__) do
        get url
        assert_result :success, options
      end
    end

    test 'healthcheck' do
      url     = healthcheck_url
      options = OPTIONS.merge(action: 'check')
      run_test(__method__) do
        get url
        assert_result :success, options
      end
    end

    test 'health check - all subsystem statuses' do
      url     = check_health_url
      options = OPTIONS.merge(action: 'check')
      run_test(__method__) do
        get url
        assert_result :success, options
      end
    end

    test 'health check - single subsystem status' do
      url     = check_subsystem_health_url(subsystem: TEST_SUBSYSTEM)
      options = OPTIONS.merge(action: 'check')
      run_test(__method__) do
        get url
        assert_result :success, options
      end
    end

  end

end
