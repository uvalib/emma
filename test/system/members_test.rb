# test/system/members_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class MembersTest < ApplicationSystemTestCase

  TEST_USER = EMMA_DSO

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'members - visit index' do
    run_test(__method__) do

      url = member_index_url

      # Not available anonymously.
      visit url
      assert_flash alert: 'You need to sign in'

      # Successful sign-in should redirect back.
      sign_in_as(TEST_USER)
      show_url
      assert_current_url url

      # The listing should be the first of one or more results pages.
      assert_valid_index_page(:member, page: 0)

    end
  end

end
