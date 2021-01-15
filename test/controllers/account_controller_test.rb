# test/controllers/account_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class AccountControllerTest < ActionDispatch::IntegrationTest

=begin
  setup do
    @user = users(:one)
  end
=end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

=begin # TODO: test controller account/index
  test 'account index - list all user accounts' do
    get account_index_url
    assert_response :success
  end
=end

=begin # TODO: test controller account/show
  test 'account show - details of an existing user account' do
    get account_url(@user)
    assert_response :success
  end
=end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

=begin # TODO: test controller account/new
  test 'account new - user account form' do
    get new_account_url
    assert_response :success
  end
=end

=begin # TODO: test controller account/new
  test 'account create - a new user account' do
    assert_difference('User.count') do
      post account_url, params: { user: {  } }
    end
    assert_redirected_to account_url(User.last)
  end
=end

=begin # TODO: test controller account/edit
  test 'account edit - user account edit form' do
    get edit_account_url(@user)
    assert_response :success
  end
=end

=begin # TODO: test controller account/update
  test 'account update - modify an existing user account' do
    patch account_url(@user), params: { user: {  } }
    assert_redirected_to account_url(@user)
  end
=end

=begin # TODO: test controller account/destroy
  test 'account destroy - remove an existing user account' do
    assert_difference('User.count', -1) do
      delete account_url(@user)
    end
    assert_redirected_to account_url
  end
=end

end
