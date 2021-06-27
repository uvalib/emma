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

# NOTE: Temporary until all databases have been automatically modified
Role.all.order(:id).map { |record|
  # noinspection RubyCaseWithoutElseBlockInspection
  new_name =
    case (old_name = record.name)
      when 'catalog_searcher'    then 'catalog_search'
      when 'catalog_submitter'   then 'catalog_submit'
      when 'artifact_downloader' then 'artifact_download'
      when 'artifact_submitter'  then 'artifact_submit'
      when 'membership_viewer'   then 'membership_view'
      when 'membership_manager'  then 'membership_modify'
    end
  next unless new_name
  Log.warn { "******** UPDATE ROLE TABLE #{old_name} => #{new_name} ********" }
  record.update(name: new_name)
}.compact.tap { |a|
  Log.warn { '******** ROLE TABLE ALREADY UPDATED *************' } if a.empty?
}

__loading_end(__FILE__)
