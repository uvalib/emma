# app/models/org.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Org < ApplicationRecord

  include Model

  include Record
  include Record::Assignable
  include Record::Authorizable
  include Record::Searchable

  include Record::Testing
  include Record::Debugging

  include Org::Config

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :long_name

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  has_many :users

  has_many :uploads,   through: :users
  has_many :manifests, through: :users

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  def org_id = id

  # A textual label for the record instance.
  #
  # @param [Org, nil] item  Default: self.
  #
  # @return [String, nil]
  #
  def label(item = nil)
    (item || self).long_name.presence
  end

  # Create a new instance.
  #
  # @param [Org, Hash, nil] attr   Passed to #assign_attributes via super.
  #
  # @note - for dev traceability
  #
  def initialize(attr = nil, &block)
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def user_ids
    users.pluck(:id)
  end

  def user_emails
    users.pluck(:email)
  end

end

__loading_end(__FILE__)
