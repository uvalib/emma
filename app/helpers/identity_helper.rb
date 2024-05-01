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
    case user
      when User then user.has_role?(role)
      when nil  then false
      else           raise "#{__method__}: invalid user: #{user.inspect}"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The organization of the current user.
  #
  # @return [Org, nil]
  #
  def current_org
    current_user&.org
  end

  # The organization ID associated with the current user.
  #
  # @raise [RuntimeError]             The user should have an org and doesn't.
  #
  # @return [Integer, nil]
  #
  def current_org_id
    return if current_user.nil? || administrator?
    current_org&.id&.presence or raise("no org for #{current_user}")
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
