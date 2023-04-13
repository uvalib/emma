# test/controllers/health_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class HealthControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER     = :health
  OPTIONS        = { controller: CONTROLLER, format: :json }.freeze

  READ_FORMATS   = :html

  TEST_SUBSYSTEM = 'storage'

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'version' do
    options = OPTIONS.merge(action: :version)
    url     = version_url
    run_test(__method__, only: READ_FORMATS) do
      get url
      assert_result :success, **options
    end
  end

  test 'health version' do
    options = OPTIONS.merge(action: :version)
    url     = version_health_url
    run_test(__method__, only: READ_FORMATS) do
      get url
      assert_result :success, **options
    end
  end

  test 'healthcheck' do
    options = OPTIONS.merge(action: :check)
    url     = healthcheck_url
    run_test(__method__, only: READ_FORMATS) do
      get url
      assert_result :success, **options
    end
  end

  test 'health check - all subsystem statuses' do
    options = OPTIONS.merge(action: :check)
    url     = check_health_url
    run_test(__method__, only: READ_FORMATS) do
      get url
      assert_result :success, **options
    end
  end

  test 'health check - single subsystem status' do
    options = OPTIONS.merge(action: :check)
    url     = check_subsystem_health_url(subsystem: TEST_SUBSYSTEM)
    run_test(__method__, only: READ_FORMATS) do
      get url
      assert_result :success, **options
    end
  end

end
