# test/controllers/health_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class HealthControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER     = :health
  PARAMS         = { controller: CONTROLLER }.freeze
  OPTIONS        = { controller: CONTROLLER }.freeze

  TEST_USERS     = ALL_TEST_USERS
  TEST_READERS   = TEST_USERS

  TEST_SUBSYSTEM = 'storage'

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'version' do
    url = version_url
    check_url_test(:version, url, meth: __method__)
  end

  test 'health version' do
    url = version_health_url
    check_url_test(:version, url, meth: __method__)
  end

  test 'healthcheck' do
    url = healthcheck_url
    check_url_test(:check, url, meth: __method__)
  end

  test 'health check - all subsystem statuses' do
    url = check_health_url
    check_url_test(:check, url, meth: __method__)
  end

  test 'health check - single subsystem status' do
    url = check_subsystem_health_url(subsystem: TEST_SUBSYSTEM)
    check_url_test(:check, url, meth: __method__)
  end

  test 'health run_state' do
    action  = :run_state
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    find_users(*TEST_READERS).each do |user|
      u_opt = options
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # Perform a HealthController test.
  #
  # @param [Symbol] action
  # @param [String] url
  # @param [Symbol] meth              Calling test method.
  #
  # @return [void]
  #
  def check_url_test(action, url, meth: nil)
    meth  ||= __method__
    options = OPTIONS.merge(action: action)
    run_test(meth, format: :json) do
      get url
      assert_result :success, **options
    end
  end

end
