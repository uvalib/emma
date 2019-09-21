# test/test_helper/integration_tests/role.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for sign-in.
#
module TestHelper::IntegrationTests::Role

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether *user* should be able to perform *action* on *subject*.
  #
  # @param [User, String, nil] user
  # @param [Symbol, String]    action
  # @param [Class]             subject
  #
  def can?(user, action, subject)
    user = users(user.sub(/@.*/, '')) if user.is_a?(String)
    Ability.new(user).can?(action, subject)
  end

end
