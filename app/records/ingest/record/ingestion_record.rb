# app/records/ingest/record/ingestion_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata ingestion schema for EMMA Federated Search Index.
#
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/IngestionRecord   JSON schema specification
#
# @see file:config/locales/records/entry.en.yml *en.emma.entry.record.emma_data*
#
# @see Search::Record::MetadataCommonRecord (duplicate schema)
#
class Ingest::Record::IngestionRecord < Ingest::Api::Record

  include Emma::Common

  include Ingest::Shared::CreatorMethods
  include Ingest::Shared::DateMethods
  include Ingest::Shared::IdentifierMethods
  include Ingest::Shared::TitleMethods
  include Ingest::Shared::TransformMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Search::Record::MetadataCommonRecord

  # ===========================================================================
  # :section: Api::Record overrides
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Model, Hash, String, nil] src
  # @param [Hash, nil]                                   opt
  #
  # @option opt [String] :value       If *src* is *nil*, a unique record ID may
  #                                     be provided here as the value for the
  #                                     instance.
  #
  # @raise [Record::SubmitError]      If metadata was malformed.
  #
  def initialize(src, opt = nil)
    # noinspection RailsParamDefResolve
    if (data = src.try(:emma_metadata) || src.try(:dig, :emma_metadata))
      # === Dates ===
      data[:emma_lastRemediationDate]          ||= src[:updated_at]
      data[:emma_repositoryMetadataUpdateDate] ||= src[:updated_at]
      # === Required fields ===
      data[:emma_repository]         ||= src[:repository]
      data[:emma_repositoryRecordId] ||= src[:submission_id]
      data[:dc_title]                ||= MISSING_TITLE
      data[:dc_format]               ||= FileFormat.metadata_fmt(src[:fmt])
    end
    opt ||= {}
    super((data || src), **opt)
    normalize_data_fields!
  end

end

__loading_end(__FILE__)
