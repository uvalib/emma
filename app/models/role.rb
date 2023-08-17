# app/models/role.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for a role.
#
class Role < ApplicationRecord

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :id

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

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
  # :section: ActiveRecord validations
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

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Current EMMA roles.
  #
  # A role "capability" aligns with a set of actions that a user's session
  # would be permitted to perform in the system.  These are the roles that
  # Rolify manages.
  #
  # @type [Array<Symbol>]
  #
  CAPABILITIES = %i[
    searcher
    submitter
    downloader
    manager
    administrator
    developer
  ].freeze

  # EMMA role(s) for prototypical users.
  #
  # A role "prototype" aligns with the nature of the user's institutional role.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  # === Usage Notes
  # End-users are not a part of EMMA at this time.
  #
  PROTOTYPE = {
    developer:     CAPABILITIES,
    administrator: CAPABILITIES.excluding(:developer),
    manager:       CAPABILITIES.excluding(:developer, :administrator),
    dso:           %i[searcher submitter downloader],
    staff:         %i[searcher submitter],
    guest:         %i[searcher],
    anonymous:     %i[searcher],
  }.deep_freeze

  # The name of the default set of roles for a new user.
  #
  # @type [Symbol]
  #
  DEFAULT_PROTOTYPE = :dso

  # Indicate the nature of the given user.
  #
  # @param [User, String, nil] user
  #
  # @return [Symbol]                  Best-match #PROTOTYPE key.
  #
  def self.prototype_for(user)
    user  = User.find_by(uid: user) if user.is_a?(String)
    roles = (user.role_list         if user.is_a?(User))
    case roles&.last
      when :developer     then :developer
      when :administrator then :administrator
      when :manager       then :manager
      when :downloader    then :dso
      when :submitter     then :staff
      when :searcher      then :guest
      else                     :anonymous
    end
  end

end

__loading_end(__FILE__)
