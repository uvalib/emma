# test/controllers/home_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class HomeControllerTest < ApplicationControllerTestCase

  CTRLR = :home
  PRM   = {}.freeze
  OPT   = { controller: CTRLR, sign_out: false }.freeze

  TEST_READERS = %i[anonymous test_guest_1 test_dso_1 test_adm].freeze

  READ_FORMATS = :html

  NO_READ      = formats_other_than(*READ_FORMATS).freeze

  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'home main as anonymous' do
    # action  = :main
    # options = OPT.merge(action: action)
    params = PRM

    TEST_FORMATS.each do |fmt|
      url = home_url(**params, format: fmt)

      run_test(__method__, format: fmt, only: READ_FORMATS) do
        get(url)
        assert_redirected_to welcome_url
      end
    end
  end

  test 'home main as test_dso_1' do
    # action  = :main
    # options = OPT.merge(action: action)
    params = PRM
    user   = :test_dso_1

    TEST_FORMATS.each do |fmt|
      url = home_url(**params, format: fmt)

      run_test(__method__, format: fmt, only: READ_FORMATS) do
        get_sign_in_as(user, follow_redirect: false)
        get(url)
        assert_redirected_to dashboard_url
      end
    end
  end

  test 'home welcome' do
    action  = :welcome
    options = OPT.merge(action: action)
    params  = PRM

    TEST_FORMATS.each do |fmt|
      url = welcome_url(**params, format: fmt)
      opt = options.merge(format: fmt)

      run_test(__method__, format: fmt, only: READ_FORMATS) do
        get(url)
        assert_result(:success, **opt)
      end
    end
  end

  test 'home dashboard' do
    action  = :dashboard
    options = OPT.merge(action: action, test: __method__, expect: :success)
    params  = PRM

    @readers.each do |user|
      able  = user.present?
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = dashboard_url(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          opt[:expect] = :unauthorized unless able
        end
        get_as(user, url, **opt)
      end
    end
  end

end
