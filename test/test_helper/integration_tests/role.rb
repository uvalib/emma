# test/test_helper/integration_tests/role.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for sign-in.
#
module TestHelper::IntegrationTests::Role

  include TestHelper::Utility

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether *user* should be able to perform *action* on *subject*.
  #
  # @param [String, Symbol, User, nil] user
  # @param [Symbol, String]            action
  # @param [Class]                     subject
  # @param [*]                         extra_args
  #
  def can?(user, action, subject, *extra_args)
    ability = find_user(user)&.ability || Ability.new
    ability.can?(action, subject, *extra_args)
  end

end
