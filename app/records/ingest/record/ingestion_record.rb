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
# @see "en.emma.upload.record.emma_data" in config/locales/records/upload.en.yml
#
#--
# noinspection DuplicatedCode
#++
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

  # Because :dc_title is a required field for ingest into Unified Search, this
  # value is supplied if the metadata does not include a title.
  #
  # @type [String, nil] # TODO: MISSING_TITLE: I18n - keep?
  #
  MISSING_TITLE = '[TITLE MISSING]'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, ::Api::Record, Upload, Hash, String, nil] src
  # @param [Hash]                                                        opt
  #
  # @option opt [String] :value       If *src* is *nil*, a unique record ID may
  #                                     be provided here as the value for the
  #                                     instance.
  #
  # @raise [UploadWorkflow::SubmitError]  If metadata was malformed.
  #
  def initialize(src, **opt)
    if src.is_a?(Upload)
      # noinspection RubyNilAnalysis
      data = reject_blanks(src.emma_metadata)

      # === Standard Identifiers ===
      data[:dc_identifier] = normalize_identifiers(data[:dc_identifier])
      data[:dc_relation]   = normalize_identifiers(data[:dc_relation])

      # === Dates ===
      data[:emma_lastRemediationDate]          ||= src[:updated_at]
      data[:emma_repositoryMetadataUpdateDate] ||= src[:updated_at]

      # === Required fields ===
      data[:emma_repository]         ||= src[:repository]
      data[:emma_repositoryRecordId] ||= src[:submission_id]
      data[:dc_title]                ||= MISSING_TITLE
      data[:dc_format]               ||= FileFormat.metadata_fmt(src[:fmt])

      initialize_attributes(reject_blanks(data))
    else
      super(src, **opt)
    end
    self.emma_retrievalLink ||= make_retrieval_link
    @serializer_type ||= DEFAULT_SERIALIZER_TYPE # TODO: remove
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Produce standard identifiers of the form "#{prefix}:#{value}".
  #
  # @param [ActiveRecord::Associations::CollectionAssociation, Array<String,PublicationIdentifier>] ids
  #
  # @return [Array<String>]
  #
  # == Variations
  #
  # @overload normalize_identifiers(ids)
  #   @param [ActiveRecord::Associations::CollectionAssociation] ids
  #
  # @overload normalize_identifiers(ids)
  #   @param [Array<String,PublicationIdentifier>] ids
  #
  def normalize_identifiers(ids)
    Array.wrap(ids).map { |id| PublicationIdentifier.cast(id)&.to_s }.compact
  end

  # Produce a retrieval link for an item.
  #
  # @param [String] rid               An EMMA repository record ID.
  #
  # @return [String]
  # @return [nil]                     If no repository ID was given or found.
  #
  def make_retrieval_link(rid = nil)
    rid ||= (emma_repositoryRecordId rescue nil)
    Upload.make_retrieval_link(rid)
  end

end

__loading_end(__FILE__)
