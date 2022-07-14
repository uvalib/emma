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
  # @param [String, Symbol, User, nil] user_name
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def sign_in_as(user_name)
    user = find_user(user_name)
    raise Minitest::Assertion, "#{__method__}: no user" unless user
    visit new_user_session_url
    click_on "Sign in as #{user.email}"
    assert_flash notice: 'Signed in'
  end

end
