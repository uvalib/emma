# app/records/ingest/record/identifier_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Ingest::Record::IdentifierRecord
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
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.2#/components/schemas/IdentifierRecord
#
class Ingest::Record::IdentifierRecord < Ingest::Api::Record

  include Emma::Common

  schema do
    attribute :emma_recordId,             String
    attribute :emma_repository,           EmmaRepository
    attribute :emma_repositoryRecordId,   String
    attribute :emma_formatVersion,        String
    attribute :dc_format,                 DublinCoreFormat
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Hash]                                              opt
  #
  # @option opt [String] :value       If *src* is *nil*, a unique record ID may
  #                                     be provided here as the value for the
  #                                     instance.
  #
  # This method overrides:
  # @see Api::Record#initialize
  #
  def initialize(src, **opt)
    @serializer_type ||= DEFAULT_SERIALIZER_TYPE
    initialize_attributes unless src.is_a?(Api::Record)
    if src.blank?
      self.emma_recordId = opt[:value].to_s
    elsif src.is_a?(Upload)
      attr = remove_blanks(src.emma_metadata.slice(*field_names))
      attr[:emma_repository]         ||= src[:repository]
      attr[:emma_repositoryRecordId] ||= src[:repository_id] || src[:id]
      attr[:dc_format]               ||= src[:fmt]
      initialize_attributes(attr)
    else
      super(src, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The unique identifier represented by this instance.
  #
  # @return [String, nil]
  #
  def identifier
    emma_recordId.presence ||
      [emma_repository, emma_repositoryRecordId, dc_format, emma_formatVersion]
        .reject(&:blank?).join('-').presence
  end

end

__loading_end(__FILE__)
