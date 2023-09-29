# app/services/search_service/action/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Action::Records
#
module SearchService::Action::Records

  include SearchService::Common
  include SearchService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /search
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
  # @note According the documentation for API 0.0.4, :publisher searches do not
  #   work when combined with :q searches.
  #
  # === Control Parameters
  # The single-select :sort parameter controls the order in which items of the
  # result set are delivered.
  #
  # === Filters
  # If :repository is given, results will be limited to items originating from
  # the specified partner repository.
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
  # === Pagination
  # One of two methods, depending on whether the results are not sorted (i.e.
  # sorted by relevance) due to a limitation with the way Elasticsearch is
  # being used.
  #
  # * Paging with :from
  #   Returns the next page of results starting from the given result number.
  #   Limited to 10,000 total results.
  #
  # * Paging with :searchAfterId and :searchAfterValue
  #   Returns the next page of sorted results which come after the EMMA Record
  #   Identifier (:emma_recordId) specified in :searchAfterId and URL-encoded
  #   title or date (:dc_title or :emma_lastRemediationDate) specified in
  #   :searchAfterValue.
  #
  # === Group
  # (EXPERIMENTAL) Search results will be grouped by the given field.  Result
  # page size will automatically be limited to 10 maximum.  Each result will
  # have a number of grouped records provided as children, so the number of
  # records returned will be more than 10.  Cannot be combined with sorting by
  # title or date.
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
  # @option opt [IsoDay]                                  :publicationDate
  # @option opt [IsoDay]                                  :sortDate
  # @option opt [SearchSort]                              :sort
  # @option opt [String]                                  :searchAfterId
  # @option opt [String]                                  :searchAfterValue
  # @option opt [Integer]                                 :size
  # @option opt [Integer]                                 :from
  # @option opt [SearchGroup, Array<SearchGroup>]         :group
  #
  # @return [Search::Message::SearchRecordList]
  #
  # === HTTP response codes
  #
  # 200 Accepted        Metadata records matching the search criteria.
  # 400 Bad Request     Bad query parameter.
  #
  # @see https://app.swaggerhub.com/apis/bus/emma-federated-search-api/0.0.5#/search/searchMetadata  HTML API documentation
  # @see https://api.swaggerhub.com/apis/bus/emma-federated-search-api/0.0.5#/paths/search           JSON API specification
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
          offset:               :from,
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
          publicationDate:      IsoDay,
          sortDate:             IsoDay,
          sort:                 SearchSort,
          searchAfterId:        String,
          searchAfterValue:     String,
          size:                 Integer,
          from:                 Integer,
          group:                SearchGroup,
        },
        multi: %i[
          format
          formatFeature
          accessibilityFeature
          collection
          group
        ],
        role:  :anonymous, # Should succeed for any user.
      }
    end

  # === GET /record/:id
  # === GET /record/:record_id
  #
  # @param [String] record_id         Query.
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Search::Message::SearchRecord]
  #
  # @note This method is not actually functional because it depends on an EMMA
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

end

__loading_end(__FILE__)
