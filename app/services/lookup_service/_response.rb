# app/services/lookup_service/_response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A collection of identifiers transformed into PublicationIdentifier and
# grouped by type.
#
# @see LookupChannel::Response
#
class LookupService::Response < ApplicationJob::Response

  include LookupService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DEFAULT_SERVICE = 'unknown'

  TEMPLATE = LookupChannel::Response::TEMPLATE

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [any, nil] values          LookupService::Response, Hash
  # @param [Hash]     opt
  #
  def initialize(values = nil, **opt)
    super
    @table[:service] ||= DEFAULT_SERVICE
  end

  # ===========================================================================
  # :section: ApplicationJob::Response overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

end

__loading_end(__FILE__)
