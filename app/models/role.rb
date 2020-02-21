# app/models/role.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for a role.
#
class Role < ApplicationRecord

  include Roles

  has_and_belongs_to_many :users

  # noinspection RailsParamDefResolve
  belongs_to :resource, polymorphic: true, optional: true

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Not applicable.

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  scopify

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  validates :resource_type, allow_nil: true,
            inclusion: { in: Rolify.resource_types }

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Display the User instance as the user identifier.
  #
  # @return [String]
  #
  def to_s
    name.to_s
  end

end

__loading_end(__FILE__)
