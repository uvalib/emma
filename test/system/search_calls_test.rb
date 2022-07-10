# test/system/search_calls_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class SearchCallsTest < ApplicationSystemTestCase

  CONTROLLER = :search_call
  TEST_USER  = :developer

  # noinspection RbsMissingTypeSignature
  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'search calls - visit index' do

    url = search_call_index_url

    run_test(__method__) do

      # Not available anonymously.
      visit url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Successful sign-in should redirect back.
      show_url
      assert_current_url url

      # The listing should be the first of one or more results pages.
      assert_valid_index_page(CONTROLLER, page: 0)
      success_screenshot

    end

  end

end
