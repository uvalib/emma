# app/records/ingest/record/ingestion_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Ingest::Record::IngestionRecord
#
# @attr [EmmaRepository]                emma_repository              *REQUIRED*
# @attr [Array<String>]                 emma_collection
# @attr [String]                        emma_repositoryRecordId      *REQUIRED*
# @attr [String]                        emma_retrievalLink           *REQUIRED*
# @attr [String]                        emma_webPageLink
# @attr [IsoDate]                       emma_lastRemediationDate
# @attr [IsoDate]                       emma_repositoryMetadataUpdateDate
# @attr [String]                        emma_lastRemediationNote
# @attr [String]                        emma_formatVersion
# @attr [Array<FormatFeature>]          emma_formatFeature
# @attr [String]                        dc_title                     *REQUIRED*
# @attr [Array<String>]                 dc_creator
# @attr [Array<PublicationIdentifier>]  dc_identifier
# @attr [String]                        dc_publisher
# @attr [Array<PublicationIdentifier>]  dc_relation
# @attr [Array<String>]                 dc_language
# @attr [Rights]                        dc_rights
# @attr [Provenance]                    dc_provenance
# @attr [String]                        dc_description
# @attr [DublinCoreFormat]              dc_format                    *REQUIRED*
# @attr [DcmiType]                      dc_type
# @attr [Array<String>]                 dc_subject
# @attr [IsoDate]                       dcterms_dateAccepted
# @attr [IsoYear]                       dcterms_dateCopyright
# @attr [Array<A11yFeature>]            s_accessibilityFeature
# @attr [Array<A11yControl>]            s_accessibilityControl
# @attr [Array<A11yHazard>]             s_accessibilityHazard
# @attr [Array<A11yAPI>]                s_accessibilityAPI
# @attr [String]                        s_accessibilitySummary
# @attr [Array<A11yAccessMode>]         s_accessMode
# @attr [Array<A11ySufficient>]         s_accessModeSufficient
#
# NOTE: These fields are identical to:
# @see Search::Record::MetadataCommonRecord
#
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.2#/components/schemas/IngestionRecord
#
class Ingest::Record::IngestionRecord < Ingest::Api::Record

  include Emma::Common
  include Ingest::Shared::TitleMethods

  schema do
    attribute :emma_repository,                   EmmaRepository
    has_many  :emma_collection,                   String
    attribute :emma_repositoryRecordId,           String
    attribute :emma_retrievalLink,                String
    attribute :emma_webPageLink,                  String
    attribute :emma_lastRemediationDate,          IsoDate
    attribute :emma_repositoryMetadataUpdateDate, IsoDate
    attribute :emma_lastRemediationNote,          String
    attribute :emma_formatVersion,                String
    has_many  :emma_formatFeature,                FormatFeature
    attribute :dc_title,                          String
    has_many  :dc_creator,                        String
    has_many  :dc_identifier,                     PublicationIdentifier
    attribute :dc_publisher,                      String
    has_many  :dc_relation,                       PublicationIdentifier
    has_many  :dc_language,                       String
    attribute :dc_rights,                         Rights
    attribute :dc_provenance,                     Provenance
    attribute :dc_description,                    String
    attribute :dc_format,                         DublinCoreFormat
    attribute :dc_type,                           DcmiType
    has_many  :dc_subject,                        String
    attribute :dcterms_dateAccepted,              IsoDate
    attribute :dcterms_dateCopyright,             IsoYear
    has_many  :s_accessibilityFeature,            A11yFeature
    has_many  :s_accessibilityControl,            A11yControl
    has_many  :s_accessibilityHazard,             A11yHazard
    has_many  :s_accessibilityAPI,                A11yAPI
    attribute :s_accessibilitySummary,            String
    has_many  :s_accessMode,                      A11yAccessMode
    has_many  :s_accessModeSufficient,            A11ySufficient
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
    $stderr.puts "CREATE IngestionRecord | src (#{src.class}) = #{src.inspect} | opt = #{opt.inspect}"
    $stderr.puts "CREATE IngestionRecord | default_data = #{default_data.inspect}"
    if src.is_a?(Upload)
      $stderr.puts "CREATE IngestionRecord | src.updated_at = #{src[:updated_at].inspect}"
      $stderr.puts "CREATE IngestionRecord | src.repository = #{src[:repository].inspect}"
      $stderr.puts "CREATE IngestionRecord | src.repository_id = #{src[:repository_id].inspect}"
      $stderr.puts "CREATE IngestionRecord | src.fmt = #{src[:fmt].inspect}"
      data = reject_blanks(src.emma_metadata)
      $stderr.puts "CREATE IngestionRecord | src.emma_metadata = #{src.emma_metadata.inspect}"

      # === Standard Identifiers ===
      data[:dc_identifier] = normalize_identifiers(data[:dc_identifier])
      data[:dc_relation]   = normalize_identifiers(data[:dc_relation])

      # === Dates ===
      data[:emma_lastRemediationDate]          ||= src[:updated_at]
      data[:emma_repositoryMetadataUpdateDate] ||= src[:updated_at]

      # === Required fields ===
      data[:emma_repository]         ||= src[:repository]
      data[:emma_repositoryRecordId] ||= src[:repository_id] || src[:id]
      data[:emma_retrievalLink]        = make_retrieval_link(data[:emma_retrievalLink])
      data[:dc_title]                ||= 'TITLE MISSING' # TODO: ???
      data[:dc_format]               ||= src[:fmt]

      initialize_attributes(reject_blanks(data))
    else
      super(src, **opt)
    end
    @serializer_type ||= DEFAULT_SERIALIZER_TYPE # TODO: remove
    $stderr.puts "CREATE IngestionRecord | final fields = #{fields.inspect}" # TODO: remove
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Produce standard identifiers of the form "#{prefix}:#{value}".
  #
  # @overload normalize_identifiers(ids)
  #   @param [ActiveRecord::Associations::CollectionAssociation] ids
  #
  # @overload normalize_identifiers(ids)
  #   @param [Array<String,PublicationIdentifier>] ids
  #
  # @return [Array<String>]
  #
  def normalize_identifiers(ids)
    Array.wrap(ids).map { |id| PublicationIdentifier.cast(id)&.to_s }.compact
  end

  # Produce a retrieval link for an item.
  #
  # @param [String] value
  #
  # @return [String]
  #
  def make_retrieval_link(value)
    'https://emmadev.internal.lib.virginia.edu' # TODO: ???
  end

end

__loading_end(__FILE__)
