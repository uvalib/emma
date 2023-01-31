# test/system/accounts_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class AccountsTest < ApplicationSystemTestCase

  TEST_USER = :emmadso

  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'accounts - visit index' do
    run_test(__method__) do

      visit account_index_url
      assert_valid_page 'EMMA User Accounts'
      # ...

    end unless not_applicable 'TODO: test account/index'
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'accounts - creating a user account' do
    run_test(__method__) do

      visit account_index_url
      click_on 'Create'
      # ...

    end unless not_applicable 'TODO: test account/new'
  end

  test 'accounts - updating a user account' do
    run_test(__method__) do

      visit account_index_url
      click_on 'Change'
      # ...

    end unless not_applicable 'TODO: test account/edit'
  end

  test 'accounts - destroying a user account' do
    run_test(__method__) do

      visit account_index_url
      click_on 'Remove'
      # ...

    end unless not_applicable 'TODO: test account/delete'
  end

end
