# app/records/search/record/metadata_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata record schema for EMMA Federated Search Index.
#
# == API description
# Schema for JSON documents which are retrieved from the EMMA Federated Search
# Index ingestion service.
#
#--
# === Unified Index Fields
#++
# @attr [String]      emma_recordId
# @attr [String]      emma_titleId
#--
# === Fields not yet supported by the Unified Index
#++
# @attr [String]      bib_series
# @attr [SeriesType]  bib_seriesType
# @attr [String]      bib_seriesPosition
#
# @see https://app.swaggerhub.com/apis/bus/emma-federated-search-api/0.0.5#/MetadataRecord                               Search API documentation
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/MetadataRecord  JSON schema specification
#
# @see Search::Message::SearchRecord        (duplicate schema)
# @see Search::Record::MetadataCommonRecord (schema subset)
# @see Ingest::Record::IngestionRecord      (schema subset)
# @see AwsS3::Message::SubmissionRequest    (schema superset)
#
class Search::Record::MetadataRecord < Search::Api::Record

  include Search::Shared::CreatorMethods
  include Search::Shared::DateMethods
  include Search::Shared::IdentifierMethods
  include Search::Shared::LinkMethods
  include Search::Shared::ScoreMethods
  include Search::Shared::TitleMethods
  include Search::Shared::TransformMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do

    has_one :emma_recordId
    has_one :emma_titleId

    all_from Search::Record::MetadataCommonRecord

    has_one :bib_series
    has_one :bib_seriesType,    SeriesType
    has_one :bib_seriesPosition

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Message, Model, Hash, String, nil] src
  # @param [Hash, nil]                                                 opt
  #
  def initialize(src = nil, opt = nil)
    opt ||= {}
    # noinspection RubyMismatchedArgumentType
    super(src, **opt)
    normalize_data_fields!
  end

end

__loading_end(__FILE__)
