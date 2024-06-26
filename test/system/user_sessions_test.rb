# test/system/user_sessions_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class UserSessionsTest < ApplicationSystemTestCase

  TEST_USER = :test_dso_1

  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'user session - sign in' do

    start_url = root_url

    run_test(__method__) do

      # Start on the main page.
      visit start_url
      click_on class: 'session-login'

      # On sign-in page '/users/sign_in' (#new_user_session_path).
      show_url
      assert_valid_page('Sign in')
      assert_link href: user_shibboleth_omniauth_authorize_path if SHIBBOLETH
      click_on "Sign in as #{@user}"

      # On dashboard page '/dashboard' (#dashboard_path).
      show_url
      assert_valid_page('EMMA Account Dashboard')
      assert_flash(notice: 'Signed in')

    end
  end

  test 'user session - sign out' do

    start_url = root_url

    run_test(__method__) do

      # Sign in.
      visit start_url
      sign_in_as(@user)

      # Go to a new page.
      visit_index :search, title: 'Advanced'
      click_on class: 'session-logout'
      assert_flash notice: 'signed out'

    end
  end

end
