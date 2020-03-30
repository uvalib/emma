# app/services/search_service/request/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Records
#
# noinspection RubyParameterNamingConvention
module SearchService::Request::Records

  include SearchService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /search
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]                                  :q
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
          fmt:                  :format,
          query:                :q,
        },
        optional: {
          q:                    String,
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
