# app/services/lookup_service/google_books/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::GoogleBooks::Common
#
module LookupService::GoogleBooks::Common

  include LookupService::RemoteService::Common

  include LookupService::GoogleBooks::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If *true*,  the service should return compact JSON.
  # If *false*, the service should return formatted JSON.
  #
  # @type [Boolean]
  #
  DEF_COMPACT = true

  # If *true*,  allow foreign language results.
  # If *false*, limit results to English-language items.
  #
  # @type [Boolean]
  #
  DEF_FOREIGN = true

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  # Extract API parameters from *opt* with adjustments.
  #
  # @param [Symbol]  meth             Calling method.
  # @param [Boolean] compact          If *false*, allow formatted results.
  # @param [Boolean] foreign          If *false*, only English results.
  # @param [Hash]    opt              Passed to super.
  #
  # @return [Hash]                    Just the API parameters from *opt*.
  #
  def get_parameters(meth, compact: DEF_COMPACT, foreign: DEF_FOREIGN, **opt)
    super(meth, **opt).tap do |result|
      result[:langRestrict] = 'en' unless foreign || result.key?(:langRestrict)
      result[:prettyPrint]  = !compact unless result.key?(:prettyPrint)
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
    base.include(LookupService::GoogleBooks::Definition)
  end

end

__loading_end(__FILE__)
