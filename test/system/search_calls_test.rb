# test/system/search_calls_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class SearchCallsTest < ApplicationSystemTestCase

  TEST_USER = EMMA_DSO
  TEST_USER = EMMA_COLLECTION # TODO: why isn't this failing?

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'search calls - visit index' do
    run_test(__method__) do

      url = search_call_index_url

      # Not available anonymously.
      visit url
      assert_flash alert: AUTH_FAILURE

      # Successful sign-in should redirect back.
      sign_in_as(TEST_USER)
      show_url
      assert_current_url url

      # The listing should be the first of one or more results pages.
      assert_valid_index_page(:search_call, page: 0)

    end
  end

end
