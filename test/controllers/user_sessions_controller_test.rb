# test/controllers/user_sessions_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class UserSessionsControllerTest < ApplicationControllerTestCase

  CTRLR = :user_sessions
  PRM   = {}.freeze
  OPT   = { controller: CTRLR, format: :html }.freeze

  READ_FORMATS = :all

  setup do
    @member = find_user(:test_dso_1)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'user/sessions new - sign-in page' do
    opt = OPT.merge(action: :new)
    prm = PRM

    run_test(__method__, only: READ_FORMATS) do
      url = new_user_session_url(**prm)
      get(url)
      assert_result(:success, **opt)
    end
  end

  test 'user/sessions create - signing-in' do
    opt = OPT
    prm = PRM

    run_test(__method__, only: READ_FORMATS) do
      url = new_user_session_url(**prm)
      post(url)
      assert_result(:success, **opt)
      get_sign_out(**opt) # Ensure the session is again anonymous.
    end
  end

  test 'user/sessions destroy - sign-out as anonymous' do
    opt = {}
    prm = PRM

    run_test(__method__, only: READ_FORMATS) do
      url = welcome_url(**prm)
      get_sign_out(**opt, follow_redirect: false)
      assert_redirected_to url
    end
  end

  test 'user/sessions sign_in_as - sign in and out test_dso_1' do
    opt = {}
    prm = PRM
    usr = @member

    run_test(__method__, only: READ_FORMATS) do

      # The session should start as anonymous.
      assert not_signed_in?

      # Sign in.
      url = dashboard_url(**prm)
      get_sign_in_as(usr, **opt, follow_redirect: false)
      assert_redirected_to url
      follow_redirect!
      assert_result(:success, **opt)
      assert signed_in?

      # Sign out.
      url = welcome_url(**prm)
      get_sign_out(**opt, follow_redirect: false)
      assert_redirected_to url
      follow_redirect!
      assert_result(:success, **opt)
      assert not_signed_in?

    end
  end

  test 'user/sessions create - double sign-in' do
    opt = {}
    usr = @member

    run_test(__method__, only: READ_FORMATS) do

      # The session should start as anonymous.
      assert not_signed_in?

      # Sign in.
      get_sign_in_as(usr, **opt)
      assert_result(:success, **opt)
      assert signed_in?

      # Attempt a second sign-in.
      get_sign_in_as(usr, **opt)
      assert_result(:forbidden, **opt)
      assert signed_in?

      # Ensure the session is again anonymous.
      get_sign_out
      assert not_signed_in?

    end
  end

end
