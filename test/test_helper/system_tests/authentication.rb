# test/test_helper/system_tests/authentication.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for sign-in.
#
module TestHelper::SystemTests::Authentication

  include TestHelper::Utility
  include TestHelper::SystemTests::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign in as one of the pre-configured users.
  #
  # @param [String, Symbol, User] user
  #
  # @return [void]
  #
  def sign_in_as(user)
    user = find_user(user) unless user.is_a?(String)
    visit new_user_session_url
    click_on "Sign in as #{user}"
    assert_flash notice: 'Signed in'
  end

end
