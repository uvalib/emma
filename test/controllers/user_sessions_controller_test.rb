# test/controllers/user_sessions_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class UserSessionsControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'user/sessions'
  OPTIONS      = { controller: CONTROLLER, media_type: :html }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_DSO].freeze
  TEST_READERS = TEST_USERS

  TEST_USER    = TEST_USERS.last

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'user session new - sign-in page' do
    run_test(__method__) do
      get new_user_session_path
      assert_result :success, OPTIONS.merge(action: 'new')
    end
  end

  test 'user session create - signing-in' do
    run_test(__method__) do
      if signed_in?
        post new_user_session_path
        assert_response :error
      else
        post new_user_session_path
        assert_response :success
      end
    end
  end

  test 'user session destroy - sign-out' do
    run_test(__method__) do
      if signed_in?
        get_sign_out
        assert_response :success
      else
        get_sign_out
        assert_redirected_to welcome_path
      end
    end
  end

  test 'user session - sign in as emmadso' do
    run_test(__method__) do
      if signed_in?
        get_sign_in_as(TEST_USER)
        assert_response :error
      else
        get_sign_in_as(TEST_USER)
        assert_redirected_to dashboard_path
      end
    end
  end

  test 'user session - sign in and out' do
    run_test(__method__) do

      # Guarantee the session starts as anonymous.
      get_sign_out

      # Sign in.
      get_sign_in_as(TEST_USER)
      assert_redirected_to dashboard_path

      # Sign out.
      get_sign_out
      assert_redirected_to welcome_path

      # Should be anonymous.
      assert not_signed_in?

    end
  end

end
