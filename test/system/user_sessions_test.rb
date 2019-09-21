# test/system/user_sessions_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class UserSessionsTest < ApplicationSystemTestCase

  TEST_USER = :emmadso

  # ===========================================================================
  # :section: Tests
  # ===========================================================================

  test 'user session - sign in' do
    run_test(__method__) do

      # Start on the main page.
      visit root_url
      click_link class: 'bookshare-login'

      # On sign-in page '/users/sign_in' (#new_user_session_path).
      show_url
      assert_title 'Sign in'
      assert_selector 'h1', text: 'Sign in'
      assert_link href: user_bookshare_omniauth_authorize_path
      click_link "Sign in as #{TEST_USER}"

      # On dashboard page '/dashboard' (#dashboard_path).
      show_url
      assert_title 'Dashboard'
      assert_selector 'h1', text: 'Dashboard'
      assert_flash notice: 'Signed in'

    end
  end

  test 'user session - sign out' do
    run_test(__method__) do

      # Sign in.
      visit root_url
      sign_in_as(TEST_USER)

      # Go to a new page.
      visit title_index_url
      click_link class: 'bookshare-logout'
      assert_flash notice: 'Signed out'

    end
  end

end
