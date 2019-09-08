# test/test_helper/system_tests/authentication.rb
#
# frozen_string_literal: true
# warn_indent:           true

#require_relative '_common'

# Support for sign-in.
#
module TestHelper::SystemTests::Authentication

  include TestHelper::SystemTests::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign in as one of the pre-configured users.
  #
  # @param [String, Symbol] user
  #
  # @return [void]
  #
  def sign_in_as(user)
    visit new_user_session_path
    click_link "Sign in as #{user}"
    assert_flash notice: 'Signed in'
  end

end
