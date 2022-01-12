# app/helpers/role_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for working with authorization roles.
#
module RoleHelper

  include Emma::Common

  include Roles

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the current user has the developer role.
  #
  # == Implementation Notes
  # Currently the :developer role applies regardless of the model.
  #
  def developer?(...)
    current_user.present? && current_user.developer?
  end

  # Indicate whether the current user has the given role.
  #
  # If *role* is blank then the method always returns *true*.
  #
  # @param [Symbol, String, nil] role
  # @param [User, nil]           user   Default: `current_user`.
  #
  def has_role?(role, user = nil)
    return true if role.blank?
    if user.nil?
      unless defined?(current_user)
        raise "#{__method__} invalid in this context"
      end
      user = current_user
    end
    return false unless user.is_a?(User)
    role = role.to_s.strip.to_sym if role.is_a?(String)
    # noinspection RubyNilAnalysis
    case role
      when :developer     then user.developer?
      when :administrator then user.administrator?
      else                     user.has_role?(role)
    end
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
