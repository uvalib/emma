# app/records/ingest/record/identifier_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata to uniquely identify a record in the EMMA Federated Search Index.
#
# Either:
#
# @attr [String]            emma_recordId
#
# Or:
#
# @attr [EmmaRepository]    emma_repository
# @attr [String]            emma_repositoryRecordId
# @attr [String]            emma_formatVersion        (optional)
# @attr [DublinCoreFormat]  dc_format
#
# @see https://app.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3#/IdentifierRecord                            Ingest API documentation
# @see https://app.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/IdentifierRecord  HTML schema documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3                                       JSON schema specification
#
class Ingest::Record::IdentifierRecord < Ingest::Api::Record

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :emma_recordId
    has_one   :emma_repository,           EmmaRepository
    has_one   :emma_repositoryRecordId
    has_one   :emma_formatVersion
    has_one   :dc_format,                 DublinCoreFormat
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Upload, Hash, String, nil] src
  # @param [Hash]                                                      opt
  #
  # @option opt [String] :value       If *src* is *nil*, a unique record ID may
  #                                     be provided here as the value for the
  #                                     instance.
  #
  # @raise [UploadWorkflow::SubmitError]  If metadata was malformed.
  #
  def initialize(src, **opt)
    @serializer_type ||= DEFAULT_SERIALIZER_TYPE
    if src.blank?
      initialize_attributes
      self.emma_recordId = opt[:value].to_s
    elsif src.is_a?(Upload)
      # noinspection RubyNilAnalysis
      attr = reject_blanks(src.emma_metadata.slice(*field_names))
      attr[:emma_repository]         ||= src[:repository]
      attr[:emma_repositoryRecordId] ||= src[:submission_id]
      attr[:dc_format]               ||= FileFormat.metadata_fmt(src[:fmt])
      initialize_attributes(attr)
    elsif src.is_a?(Hash)
      initialize_attributes(src)
    else
      initialize_attributes unless src.is_a?(Api::Record)
      super(src, **opt)
    end
    if self.emma_recordId.present? || identifier.nil?
      # Valid record or blank record.
    elsif (value = identifier(no_version: true)).nil?
      Log.error { "IdentifierRecord: invalid: #{value.inspect}" }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The unique identifier represented by this instance.
  #
  # @param [Boolean] no_version       If *true*, return "repo-rid-fmt".
  #
  # @return [String, nil]
  #
  def identifier(no_version: false)
    # noinspection RubyMismatchedReturnType
    return emma_recordId if emma_recordId.present?
    parts = [emma_repository, emma_repositoryRecordId, dc_format]
    parts << emma_formatVersion unless no_version
    parts.compact_blank.join('-').presence
  end

end

__loading_end(__FILE__)
