# app/services/search_service/request/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Request::Records
#
#--
# noinspection RubyParameterNamingConvention
#++
module SearchService::Request::Records

  include SearchService::Common

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
  # @option opt [IsoDate]                                 :lastRemediationDate
  # @option opt [IsoDate]                                 :sortDate
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
    Search::Message::SearchRecordList.new(response, error: exception)
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
          lastRemediationDate:  IsoDate,
          sortDate:             IsoDate,
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
  # == GET /record/:title_id
  #
  # @param [String] titleId           Query.
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Search::Message::SearchRecord]
  #
  # NOTE: This is theoretical -- the endpoint is not yet defined
  #
  def get_record(titleId:, **opt)
    opt.merge!(titleId: titleId)
    opt = get_parameters(__method__, **opt)
    api(:get, 'search', **opt)
    Search::Message::SearchRecord.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          titleId:              String,
        }
      }
    end

end

__loading_end(__FILE__)
