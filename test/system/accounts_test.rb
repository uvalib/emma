# test/system/accounts_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

# noinspection RubyJumpError
class AccountsTest < ApplicationSystemTestCase

  TEST_USER = :test_dso

  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'accounts - visit index' do
    return if not_applicable 'test account/index' # TODO: test account/index
    run_test(__method__) do

      visit account_index_url
      assert_valid_page 'EMMA User Accounts'
      # ...

    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'accounts - creating a user account' do
    return if not_applicable 'test account/new' # TODO: test account/new
    run_test(__method__) do

      visit account_index_url
      click_on 'Create'
      # ...

    end
  end

  test 'accounts - updating a user account' do
    return if not_applicable 'test account/edit' # TODO: test account/edit
    run_test(__method__) do

      visit account_index_url
      click_on 'Change'
      # ...

    end
  end

  test 'accounts - destroying a user account' do
    return if not_applicable 'test account/delete' # TODO: test account/delete
    run_test(__method__) do

      visit account_index_url
      click_on 'Remove'
      # ...

    end
  end

end
