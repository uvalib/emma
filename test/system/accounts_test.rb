# test/system/accounts_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class AccountsTest < ApplicationSystemTestCase

=begin
  setup do
    @user = users(:one)
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

=begin # TODO: test account/index
  test 'accounts - visit index' do
    run_test(__method__) do

      visit account_index_url
      assert_title 'EMMA User Accounts'
      assert_selector 'h1', text: 'EMMA User Accounts'
      # ...

    end
  end
=end

=begin # TODO: test account/new
  test 'accounts - creating a user account' do
    run_test(__method__) do

      visit account_index_url
      click_on 'Create'
      # ...

    end
  end
=end

=begin # TODO: test account/edit
  test 'accounts - updating a user account' do
    run_test(__method__) do

      visit account_index_url
      click_on 'Change'
      # ...

    end
  end
=end

=begin # TODO: test account/edit
  test 'accounts - destroying a user account' do
    run_test(__method__) do

      visit account_index_url
      click_on 'Remove'
      # ...

    end
  end
=end

end
