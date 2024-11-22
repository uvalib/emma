# test/controllers/health_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class HealthControllerTest < ApplicationControllerTestCase

  CTRLR = :health
  PRM   = { controller: CTRLR }.freeze
  OPT   = { controller: CTRLR, sign_out: false }.freeze

  TEST_READERS   = ALL_TEST_USERS

  READ_FORMATS   = :all

  NO_READ        = formats_other_than(*READ_FORMATS).freeze

  setup do
    @readers = find_users(*TEST_READERS)
  end

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

  test 'health check - storage subsystem status' do
    url = check_subsystem_health_url(subsystem: 'storage')
    check_url_test(:check, url, meth: __method__)
  end

  test 'health run_state' do
    action  = :run_state
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = true
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          opt[:expect] = :not_found if able
        end
        get_as(user, url, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'health controller test coverage' do
    # Endpoints covered by system tests:
    skipped = %i[
      set_run_state
    ]
    check_controller_coverage HealthController, except: skipped
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Perform a HealthController test.
  #
  # @param [Symbol] action
  # @param [String] url
  # @param [Symbol] meth              Calling test method.
  # @param [Hash]   opt               Passed to #assert_result.
  #
  # @return [void]
  #
  def check_url_test(action, url, meth: nil, **opt)
    meth ||= __method__
    opt.reverse_merge!(OPT).merge!(action: action)
    run_test(meth, format: :json) do
      get(url)
      assert_result(:success, **opt)
    end
  end

end
