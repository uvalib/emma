# test/controllers/home_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :home
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
  end

  TEST_USER = :emmadso

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'home main as anonymous' do
    # action  = :main
    # options = OPTIONS.merge(action: action)
    TEST_FORMATS.each do |fmt|
      next unless allowed_format(fmt, only: :html)
      url = home_url(format: fmt)
      run_test(__method__, format: fmt) do
        get url
        assert_redirected_to welcome_url
      end
    end
  end

  test 'home main as emmadso' do
    # action  = :main
    # options = OPTIONS.merge(action: action)
    TEST_FORMATS.each do |fmt|
      next unless allowed_format(fmt, only: :html)
      url = home_url(format: fmt)
      run_test(__method__, format: fmt) do
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
      next unless allowed_format(fmt, only: :html)
      url = welcome_url(format: fmt)
      opt = options.merge(format: fmt)
      run_test(__method__, format: fmt) do
        get url
        assert_result :success, **opt
      end
    end
  end

  test 'home dashboard' do
    action  = :dashboard
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = user.present?
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        next unless allowed_format(fmt, only: :html)
        url = dashboard_url(format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt)
      end
    end
  end

end
