# app/records/ingest/record/ingestion_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata ingestion schema for EMMA Federated Search Index.
#
# @attr [EmmaRepository]                emma_repository             *REQUIRED*
# @attr [Array<String>]                 emma_collection
# @attr [String]                        emma_repositoryRecordId     *REQUIRED*
# @attr [String]                        emma_retrievalLink          *REQUIRED*
# @attr [String]                        emma_webPageLink
# @attr [IsoDay]                        emma_lastRemediationDate
# @attr [IsoDay]                        emma_repositoryMetadataUpdateDate
# @attr [String]                        emma_lastRemediationNote
# @attr [String]                        emma_formatVersion
# @attr [Array<FormatFeature>]          emma_formatFeature
# @attr [String]                        dc_title                    *REQUIRED*
# @attr [Array<String>]                 dc_creator
# @attr [Array<PublicationIdentifier>]  dc_identifier
# @attr [String]                        dc_publisher
# @attr [Array<PublicationIdentifier>]  dc_relation
# @attr [Array<String>]                 dc_language
# @attr [Rights]                        dc_rights
# @attr [Provenance]                    dc_provenance
# @attr [String]                        dc_description
# @attr [DublinCoreFormat]              dc_format                   *REQUIRED*
# @attr [DcmiType]                      dc_type
# @attr [Array<String>]                 dc_subject
# @attr [IsoDay]                        dcterms_dateAccepted
# @attr [IsoYear]                       dcterms_dateCopyright
# @attr [Array<A11yFeature>]            s_accessibilityFeature
# @attr [Array<A11yControl>]            s_accessibilityControl
# @attr [Array<A11yHazard>]             s_accessibilityHazard
# @attr [Array<A11yAPI>]                s_accessibilityAPI
# @attr [String]                        s_accessibilitySummary
# @attr [Array<A11yAccessMode>]         s_accessMode
# @attr [Array<A11ySufficient>]         s_accessModeSufficient
#
# @see https://app.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3#/IngestionRecord                             Ingest API documentation
# @see https://app.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/IngestionRecord   HTML schema documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3                                       JSON schema specification
# @see file:config/locales/records/upload.en.yml *en.emma.upload.record.emma_data*
#
# @see Search::Record::MetadataCommonRecord (duplicate schema)
#
class Ingest::Record::IngestionRecord < Ingest::Api::Record

  include Emma::Common

  include Ingest::Shared::DateMethods
  include Ingest::Shared::IdentifierMethods
  include Ingest::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :emma_repository,                   EmmaRepository
    has_many  :emma_collection
    has_one   :emma_repositoryRecordId
    has_one   :emma_retrievalLink
    has_one   :emma_webPageLink
    has_one   :emma_lastRemediationDate,          IsoDay
    has_one   :emma_repositoryMetadataUpdateDate, IsoDay
    has_one   :emma_lastRemediationNote
    has_one   :emma_formatVersion
    has_many  :emma_formatFeature,                FormatFeature
    has_one   :dc_title
    has_many  :dc_creator
    has_many  :dc_identifier,                     PublicationIdentifier
    has_one   :dc_publisher
    has_many  :dc_relation,                       PublicationIdentifier
    has_many  :dc_language
    has_one   :dc_rights,                         Rights
    has_one   :dc_provenance,                     Provenance
    has_one   :dc_description
    has_one   :dc_format,                         DublinCoreFormat
    has_one   :dc_type,                           DcmiType
    has_many  :dc_subject
    has_one   :dcterms_dateAccepted,              IsoDay
    has_one   :dcterms_dateCopyright,             IsoYear
    has_many  :s_accessibilityFeature,            A11yFeature
    has_many  :s_accessibilityControl,            A11yControl
    has_many  :s_accessibilityHazard,             A11yHazard
    has_many  :s_accessibilityAPI,                A11yAPI
    has_one   :s_accessibilitySummary
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
  # :section: Api::Record overrides
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
      normalize_identifier_fields!(data)

      # === Dates ===
      data[:emma_lastRemediationDate]          ||= src[:updated_at]
      data[:emma_repositoryMetadataUpdateDate] ||= src[:updated_at]
      normalize_day_fields!(data)

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
