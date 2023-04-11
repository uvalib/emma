# test/controllers/account_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

# noinspection RubyJumpError
class AccountControllerTest < ActionDispatch::IntegrationTest

  TEST_USER = :test_dso

  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'account index - list all user accounts' do
    return if not_applicable 'TODO: account/index'
    get account_index_url
    assert_response :success
  end

  test 'account show - details of an existing user account' do
    return if not_applicable 'TODO: account/show'
    get show_account_url(@user)
    assert_response :success
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'account new - user account form' do
    return if not_applicable 'TODO: account/new'
    get new_account_url
    assert_response :success
  end

  test 'account create - a new user account' do
    return if not_applicable 'TODO: account/create'
    assert_difference('User.count') do
      post create_account_url, params: { user: {  } }
    end
    assert_redirected_to show_account_url(User.last)
  end

  test 'account edit - user account edit form' do
    return if not_applicable 'TODO: account/edit'
    get edit_account_url(@user)
    assert_response :success
  end

  test 'account update - modify an existing user account' do
    return if not_applicable 'TODO: account/update'
    patch update_account_url(@user), params: { user: {  } }
    assert_redirected_to show_account_url(@user)
  end

  test 'account destroy - remove an existing user account' do
    return if not_applicable 'TODO: account/destroy'
    assert_difference('User.count', -1) do
      delete destroy_account_url(@user)
    end
    assert_redirected_to account_index_url
  end

end
