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
  # EMMA Unified Search
  #
  # === Search Types
  # There are four search types:
  #
  #   :q          General (keyword) search
  #   :creator    Author search
  #   :title      Title search
  #   :identifier ISBN/ISSN/OCN/etc search.
  #
  # If two or more of these are supplied, the index treats the search as the
  # logical-AND of the search terms.
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
  # @option opt [DublinCoreFormat, Array<DublinCoreFormat>] :fmt
  # @option opt [FormatFeature, Array<FormatFeature>]     :formatFeature
  # @option opt [String]                                  :formatVersion
  # @option opt [A11yFeature, Array<A11yFeature>]         :accessibilityFeature
  # @option opt [EmmaRepository]                          :repository
  # @option opt [String, Array<String>]                   :collection
  # @option opt [IsoDate]                                 :lastRemediationDate
  # @option opt [SearchSort]                              :sort
  #
  # @return [Search::Message::SearchRecordList]
  #
  # @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api
  #
  def get_records(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'search', **opt)
    Search::Message::SearchRecordList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          author:               :creator,
          fmt:                  :format,
          query:                :q,
        },
        optional: {
          q:                    String,
          creator:              String,
          title:                String,
          identifier:           String,
          format:               DublinCoreFormat,
          formatFeature:        FormatFeature,
          formatVersion:        String,
          accessibilityFeature: A11yFeature,
          repository:           EmmaRepository,
          collection:           String,
          lastRemediationDate:  IsoDate,
          sort:                 SearchSort,
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
  # @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api
  #
  # NOTE: This is theoretical -- the endpoint is not yet defined
  #
  def get_record(titleId:, **opt)
    prm = encode_parameters(titleId: titleId)
    api(:get, 'search', **prm, **opt)
    Search::Message::SearchRecord.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          titleId:              String,
        }
      }
    end

  # ===========================================================================
  # :section: TODO: remove - testing
  # ===========================================================================

  public

  # Return fake records.
  #
  # @param [Hash] opt                 Passed to SearchRecordList#initialize.
  #
  # @return [Search::Message::SearchRecordList]
  #
  def get_example_records(**opt) # TODO: remove - testing
    opt[:example] ||= :search
    Search::Message::SearchRecordList.new(nil, opt)
  end

end

__loading_end(__FILE__)
