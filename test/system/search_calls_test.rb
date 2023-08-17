# test/system/search_calls_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class SearchCallsTest < ApplicationSystemTestCase

  CONTROLLER = :search_call
  PARAMS     = { controller: CONTROLLER }.freeze

  TEST_USER  = :test_dev

  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search calls - index' do
    action    = :index
    params    = PARAMS.merge(action: action)

    start_url = url_for(**params)
    final_url = start_url

    run_test(__method__) do

      # Not available anonymously.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Successful sign-in should redirect back.
      show_url
      assert_current_url final_url

      # The listing should be the first of one or more results pages.
      assert_valid_index_page(CONTROLLER, page: 0)
      success_screenshot

    end
  end

end
