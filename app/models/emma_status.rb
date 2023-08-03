# app/models/emma_status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Persisted application status values.
#
class EmmaStatus < ApplicationRecord

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :created_at

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  # Not applicable.

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

  # Not applicable.

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  API_VERSION_ITEM = :api_version

  # Get current EMMA data API version.
  #
  # @return [EmmaStatus, nil]
  #
  # @see #INGEST_API_KEY
  #
  def self.api_version
    # noinspection RubyMismatchedReturnType
    where(item: API_VERSION_ITEM, active: true).last
  rescue ActiveRecord::ConnectionNotEstablished
    Log.info { "#{__method__}: no database" }
  end

  # Set current EMMA data API version.
  #
  # @return [EmmaStatus, nil]
  #
  def self.api_version=(value)
    now  = DateTime.now
    attr = { active: true, updated_at: now }
    if (current = api_version)
      current.update(attr)
      current
    else
      attr.merge!(item: API_VERSION_ITEM, value: value, created_at: now)
      insert(attr)
    end
  end

end

__loading_end(__FILE__)
