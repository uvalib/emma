# app/services/search_service/request/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Request::Records
#
module SearchService::Request::Records

  include SearchService::Common
  include SearchService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /search
  #
  # EMMA Unified Search
  #
  # === Search Types
  # There are five(-ish) search types:
  #
  #   :q          General (keyword) search
  #   :creator    Author search
  #   :title      Title search
  #   :identifier ISBN/ISSN/OCN/etc search.
  #   :publisher  Publisher "filter" search.
  #
  # If two or more of these are supplied, the index treats the search as the
  # logical-AND of the search terms.
  #
  # The :publisher search is unique in that it can't be used by itself -- only
  # in conjunction with another search type and/or a filter selection.
  #
  # === Control Parameters
  # The single-select :sort parameter controls the order in which items of the
  # result set are delivered.
  #
  # === Filters
  # If :repository is given, results will be limited to items originating from
  # the specified member repository.
  #
  # If :formatVersion is given, results will be limited to items with the
  # specified format version.
  #
  # === Range Filters
  # If :lastRemediationDate is given, results will be limited to items with a
  # remediation date between that date and the present.
  #
  # === Filters (multi-select)
  # If one or more :fmt values are given, results will be limited to items with
  # one of those file formats (logical-OR).
  #
  # If one or more :formatFeature values are given, results will be limited to
  # items with at least one of the specified format features (logical-OR).
  #
  # If one or more :accessibilityFeature values are given, results will be
  # limited to items with at least one of the specified accessibility features
  # (logical-OR).
  #
  # If one or more :collection values are given, results will be limited to
  # items identified as belonging to at least one of the specified named
  # collections (logical-OR).
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]                                  :q
  # @option opt [String]                                  :creator
  # @option opt [String]                                  :title
  # @option opt [String]                                  :identifier
  # @option opt [String]                                  :publisher
  # @option opt [DublinCoreFormat, Array<DublinCoreFormat>] :fmt
  # @option opt [FormatFeature, Array<FormatFeature>]     :formatFeature
  # @option opt [String]                                  :formatVersion
  # @option opt [A11yFeature, Array<A11yFeature>]         :accessibilityFeature
  # @option opt [EmmaRepository]                          :repository
  # @option opt [String, Array<String>]                   :collection
  # @option opt [IsoDay]                                  :lastRemediationDate
  # @option opt [IsoDay]                                  :sortDate
  # @option opt [SearchSort]                              :sort
  # @option opt [String]                                  :searchAfterId
  # @option opt [String]                                  :searchAfterValue
  # @option opt [Integer]                                 :size
  #
  # @return [Search::Message::SearchRecordList]
  #
  # @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.3#/search/searchMetadata  HTML API documentation
  # @see https://api.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.3#/paths/search           JSON API specification
  #
  # == HTTP response codes
  #
  # 200 Accepted        Metadata records matching the search criteria.
  # 400 Bad Request     Bad query parameter.
  #
  def get_records(**opt)
    opt.slice(:prev_id, :prev_value).each { |k, v| opt[k] = CGI.unescape(v) }
    opt = get_parameters(__method__, **opt)
    api(:get, 'search', **opt)
    api_return(Search::Message::SearchRecordList)
  end
    .tap do |method|
      add_api method => {
        alias: {
          author:               :creator,
          fmt:                  :format,
          keyword:              :q,
          limit:                :size,
          prev_id:              :searchAfterId,
          prev_value:           :searchAfterValue,
          query:                :q,
        },
        optional: {
          q:                    String,
          creator:              String,
          title:                String,
          identifier:           String,
          publisher:            String,
          format:               DublinCoreFormat,
          formatFeature:        FormatFeature,
          formatVersion:        String,
          accessibilityFeature: A11yFeature,
          repository:           EmmaRepository,
          collection:           String,
          lastRemediationDate:  IsoDay,
          sortDate:             IsoDay,
          sort:                 SearchSort,
          searchAfterId:        String,
          searchAfterValue:     String,
          size:                 Integer,
        },
        multi: %i[
          format
          formatFeature
          accessibilityFeature
          collection
        ],
        role:  :anonymous, # Should succeed for any user.
      }
    end

  # == GET /record/:id
  # == GET /record/:record_id
  #
  # @param [String] record_id         Query.
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Search::Message::SearchRecord]
  #
  # @note This method is not actually functional because it depends on a
  #   Unified Search endpoint which does not exist.
  #
  def get_record(record_id:, **opt)
    # NOTE: In order to try out this method for test purposes, additional
    #   search terms are required in order for the API to perform a search.
    opt.merge!(q: 'RWL', fmt: DublinCoreFormat.values) if opt.blank?
    opt = get_parameters(__method__, record_id: record_id, **opt)
    api(:get, 'search', **opt)
    api_return(Search::Message::SearchRecord, recordId: record_id)
  end
    .tap do |method|
      add_api method => {
        alias: {
          fmt:        :format,          # NOTE: only for experimentation
          keyword:    :q,               # NOTE: only for experimentation
          query:      :q,               # NOTE: only for experimentation
          record_id:  :recordId,
        },
        required: {
          recordId:   String,
        },
        optional: {
          format:     DublinCoreFormat, # NOTE: only for experimentation
          q:          String,
        },
        multi: %i[format],              # NOTE: only for experimentation
        role:  :anonymous,
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  NON_PUBLISHER_SEARCH = (%i[
    collection
    formatVersion
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
  # @see ApiService::Common#get_parameters
  #
  def get_parameters(meth, check_req: true, check_opt: false, **opt)
    super.tap do |result|
      if result.key?(:publisher) && result.except(*NON_PUBLISHER_SEARCH).blank?
        result[encode_parameter(:format)] = DublinCoreFormat.values
      end
      result.delete(:sort) if result[:sort] == SearchSort.default
    end
  end

end

__loading_end(__FILE__)
