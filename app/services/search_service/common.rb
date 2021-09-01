# app/services/search_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Common
#
module SearchService::Common

  include ApiService::Common

  include SearchService::Properties

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  # api_headers
  #
  # @param [Hash]         params      Default: @params.
  # @param [Hash]         headers     Default: {}.
  # @param [String, Hash] body        Default: *nil* unless `#update_request?`.
  #
  # @return [(Hash,Hash,String)]      Message body plus headers for GET.
  # @return [(Hash,Hash,Hash)]        Query plus headers for PUT, POST, PATCH.
  #
  def api_headers(params = nil, headers = nil, body = nil)
    super.tap do |prms, _hdrs, _body|
      prms.replace(build_query_options(prms)) unless update_request?
    end
  end

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  NON_PUBLISHER_SEARCH = (%i[
    collection
    formatVersion
    from
    lastRemediationDate
    publisher
    repository
    searchAfterId
    searchAfterValue
    size
    sort
    sortDate
  ] + SERVICE_OPTIONS).freeze

  # This override silently works around a limitation of the Unified Search
  # index's handling of publisher searches.  The index treats this as a kind of
  # hybrid between a search query and a search filter -- it does not accept a
  # search which is only comprised of publisher search terms(s) alone.
  #
  # Its error message indicates that a publisher search can only be performed
  # in conjunction with another search type ("identifier", "title", "creator",
  # or "q" [keyword]) or with a filter selection from "format" ("Format" menu),
  # "formatFeature" ("Feature" menu), or "accessibilityFeature"
  # ("Accessibility" menu).
  #
  # If *opt* contains only :publisher then it adds filter selections for all of
  # the known format types.  Unless there are records without at least one
  # format type, this should make the :publisher term(s) search across all of
  # the records.
  #
  def get_parameters(meth, **opt)
    super.tap do |result|

      # Make :publisher only search work.
      if result.key?(:publisher) && result.except(*NON_PUBLISHER_SEARCH).blank?
        result[encode_parameter(:format)] = DublinCoreFormat.values
      end

      # Ensure default (relevance) sort is expressed as "no sort".
      sort = result[:sort]
      if sort == SearchSort.default
        result.delete(:sort)
        sort = nil
      end

      # Ensure pagination parameters are correct if present.
      errs = []
      if sort
        if result[:searchAfterId]
          errs << 'missing :prev_value' unless result[:searchAfterValue]
        elsif result[:searchAfterValue]
          errs << 'missing :prev_id'    unless result[:searchAfterId]
        end
        if result[:from]
          errs << "deleting :offset -- invalid for :sort == #{sort.inspect}"
          result.delete(:from)
        end
      elsif result[:searchAfterId] || result[:searchAfterValue]
        errs << ':prev_id/:prev_value -- invalid for default sort'
        result.except!(:searchAfterId, :searchAfterValue)
      end
      errs.map { |err| Log.warn { "#{__method__}: #{err}" } }

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
    base.send(:include, SearchService::Definition)
  end

end

__loading_end(__FILE__)
