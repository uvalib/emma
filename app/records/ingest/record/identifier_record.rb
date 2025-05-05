# app/records/ingest/record/identifier_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata to uniquely identify a record in the EMMA Unified Index.
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
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/IdentifierRecord  JSON schema specification
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
  # @param [Model, Hash, String nil] src
  # @param [Hash, nil]               opt
  #
  # @option opt [String] :value       If *src* is *nil*, a unique record ID may
  #                                     be provided here as the value for the
  #                                     instance.
  #
  # @raise [Record::SubmitError]      If metadata was malformed.
  #
  def initialize(src, opt = nil)
    opt ||= {}
    @serializer_type ||= DEFAULT_SERIALIZER_TYPE
    if src.blank?
      initialize_attributes
      self.emma_recordId = opt[:value].to_s
    elsif src.is_a?(String)
      initialize_attributes(emma_recordId: src)
    elsif src.is_a?(Hash)
      initialize_attributes(src)
    elsif src.respond_to?(:emma_metadata)
      attr = reject_blanks(src.emma_metadata.slice(*field_names))
      attr[:emma_repository]         ||= src[:repository]
      attr[:emma_repositoryRecordId] ||= src[:submission_id]
      attr[:dc_format]               ||= FileFormat.metadata_fmt(src[:fmt])
      initialize_attributes(attr)
    else
      initialize_attributes unless src.is_a?(Model)
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
  # @return [String]                  Can be *nil* if *no_version*.
  #
  def identifier(no_version: false)
    return emma_recordId if emma_recordId.present?
    parts = [emma_repository, emma_repositoryRecordId, dc_format]
    parts << emma_formatVersion unless no_version
    parts.compact_blank.join('-').presence
  end

end

__loading_end(__FILE__)
