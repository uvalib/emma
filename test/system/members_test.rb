# test/system/members_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class MembersTest < ApplicationSystemTestCase

  CONTROLLER = :member
  TEST_USER  = :emmadso

  # noinspection RbsMissingTypeSignature
  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'members - visit index' do

    url = member_index_url

    run_test(__method__) do

      # Not available anonymously; successful sign-in should redirect back.
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
