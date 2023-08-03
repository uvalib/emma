# app/helpers/identity_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for working with authorization roles.
#
module IdentityHelper

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the current user has the :developer role.
  #
  # === Implementation Notes
  # Currently the :developer role applies regardless of the model.
  #
  def developer?
    current_user&.developer? || false
  end

  # Indicate whether the current user has the :administrator role.
  #
  def administrator?
    current_user&.administrator? || false
  end

  # Indicate whether the current user has the :manager role.
  #
  def manager?
    current_user&.manager? || false
  end

  # Indicate whether the (current) user has the given role or role prototype.
  #
  # If *role* is blank then the method always returns *true*.
  #
  # @param [Symbol, String, nil] role
  # @param [User, nil]           user   Default: `current_user`.
  #
  def user_has_role?(role, user = nil)
    return true if role.blank?
    user = current_user if user.nil? && defined?(current_user)
    raise "#{__method__}: invalid use" unless user.is_a?(User)
    user.has_role?(role)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
