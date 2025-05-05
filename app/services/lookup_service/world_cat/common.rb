# app/services/lookup_service/world_cat/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::WorldCat::Common
#
module LookupService::WorldCat::Common

  include LookupService::RemoteService::Common

  include LookupService::WorldCat::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  WORLDCAT_SCHEMA = {
    marc:   (WORLDCAT_MARCXML     = 'info:srw/schema/1/marcxml'),
    dc:     (WORLDCAT_DUBLIN_CORE = 'info:srw/schema/1/dc'),
    default: WORLDCAT_DUBLIN_CORE
  }.freeze

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  public

  # Override service-specific API options to rename :api_key to :wskey.
  #
  # @param [Hash, nil] params         Passed to super.
  #
  # @return [Hash]                    New API parameters.
  #
  def api_options(params = nil)
    super.tap do |result|
      result[:recordSchema] ||= WORLDCAT_SCHEMA[:default]
      result[:wskey]          = result.delete(:api_key)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.include(LookupService::WorldCat::Definition)
  end

end

__loading_end(__FILE__)
