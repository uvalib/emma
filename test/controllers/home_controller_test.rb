# test/controllers/home_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :home
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous test_guest_1 test_dso_1 test_adm].freeze
  TEST_READERS = TEST_USERS

  READ_FORMATS = :html

  TEST_USER    = :test_dso_1

  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'home main as anonymous' do
    # action  = :main
    # options = OPTIONS.merge(action: action)

    TEST_FORMATS.each do |fmt|
      url = home_url(format: fmt)

      run_test(__method__, format: fmt, only: READ_FORMATS) do
        get url
        assert_redirected_to welcome_url
      end
    end
  end

  test 'home main as test_dso_1' do
    # action  = :main
    # options = OPTIONS.merge(action: action)

    TEST_FORMATS.each do |fmt|
      url = home_url(format: fmt)

      run_test(__method__, format: fmt, only: READ_FORMATS) do
        get_sign_in_as(TEST_USER, follow_redirect: false)
        get url
        assert_redirected_to dashboard_url
      end
    end
  end

  test 'home welcome' do
    action  = :welcome
    options = OPTIONS.merge(action: action)

    TEST_FORMATS.each do |fmt|
      url = welcome_url(format: fmt)
      opt = options.merge(format: fmt)

      run_test(__method__, format: fmt, only: READ_FORMATS) do
        get url
        assert_result :success, **opt
      end
    end
  end

  test 'home dashboard' do
    action  = :dashboard
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = user.present?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = dashboard_url(format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
