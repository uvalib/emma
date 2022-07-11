# test/system/reading_lists_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ReadingListsTest < ApplicationSystemTestCase

  CONTROLLER = :reading_list
  TEST_USER  = :emmadso

  # noinspection RbsMissingTypeSignature
  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'reading lists - visit index' do

    url = reading_list_index_url

    run_test(__method__) do

      # Not available anonymously.
      visit url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # The listing should be the first of one or more results pages.
      show_url
      assert_current_url url
      assert_valid_index_page(CONTROLLER, page: 0)
      success_screenshot

    end

  end

end
