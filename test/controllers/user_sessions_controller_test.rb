# test/controllers/user_sessions_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class UserSessionsControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :user_sessions
  OPTIONS      = { controller: CONTROLLER, format: :html }.freeze

  TEST_USER    = :emmadso

  READ_FORMATS = :all

  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'user session new - sign-in page' do
    options = OPTIONS.merge(action: :new)
    run_test(__method__, only: READ_FORMATS) do
      get new_user_session_url
      assert_result :success, **options
    end
  end

  test 'user session create - signing-in' do
    options = OPTIONS
    run_test(__method__, only: READ_FORMATS) do
      post new_user_session_url
      assert_result :success, **options
      get_sign_out # Ensure the session is again anonymous.
    end
  end

  test 'user session destroy - sign-out as anonymous' do
    # options = OPTIONS
    run_test(__method__, only: READ_FORMATS) do
      get_sign_out(follow_redirect: false)
      assert_redirected_to welcome_url
    end
  end

  test 'user session - sign in and out emmadso' do
    options = {}
    run_test(__method__, only: READ_FORMATS) do

      # The session should start as anonymous.
      assert not_signed_in?

      # Sign in.
      get_sign_in_as(@user, follow_redirect: false)
      assert_redirected_to dashboard_url
      follow_redirect!
      assert_result :success, **options
      assert signed_in?

      # Sign out.
      get_sign_out(follow_redirect: false)
      assert_redirected_to welcome_url
      follow_redirect!
      assert_result :success, **options
      assert not_signed_in?

    end
  end

  test 'user session create - double sign-in' do
    options = {}
    run_test(__method__, only: READ_FORMATS) do

      # The session should start as anonymous.
      assert not_signed_in?

      # Sign in.
      get_sign_in_as(@user)
      assert_result :success, **options
      assert signed_in?

      # Attempt a second sign-in.
      get_sign_in_as(@user)
      assert_result :forbidden, **options
      assert signed_in?

      # Ensure the session is again anonymous.
      get_sign_out
      assert not_signed_in?

    end
  end

end
