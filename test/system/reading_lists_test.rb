# test/system/reading_lists_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ReadingListsTest < ApplicationSystemTestCase

  TEST_USER = EMMA_DSO

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'reading lists - visit index' do
    run_test(__method__) do

      url = reading_list_index_url

      # Not available anonymously.
      visit url
      assert_flash alert: 'You need to sign in'

      # Successful sign-in should redirect back.
      sign_in_as(TEST_USER)
      show_url
      assert_current_url url

      # The listing should be the first of one or more results pages.
      assert_valid_index_page(:reading_list, page: 0)

    end
  end

end
