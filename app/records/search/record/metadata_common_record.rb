# app/records/search/record/metadata_common_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Metadata Common Fields.
#
# == API description
# Fields common to metadata ingestion records and search results.
#
#--
# === Common Emma Fields
#++
# @attr [EmmaRepository]                emma_repository
# @attr [Array<String>]                 emma_collection
# @attr [String]                        emma_repositoryRecordId
# @attr [String]                        emma_retrievalLink
# @attr [String]                        emma_webPageLink
# @attr [IsoDay]                        emma_lastRemediationDate
# @attr [IsoDay]                        emma_sortDate
# @attr [IsoDay]                        emma_repositoryMetadataUpdateDate
# @attr [IsoDay]                        emma_publicationDate
# @attr [String]                        emma_lastRemediationNote
# @attr [String]                        emma_version
# @attr [WorkType]                      emma_workType
# @attr [String]                        emma_formatVersion
# @attr [Array<FormatFeature>]          emma_formatFeature
#--
# === Dublin Core Fields
#++
# @attr [String]                        dc_title
# @attr [Array<String>]                 dc_creator
# @attr [Array<PublicationIdentifier>]  dc_identifier
# @attr [String]                        dc_publisher
# @attr [Array<PublicationIdentifier>]  dc_relation
# @attr [Array<String>]                 dc_language
# @attr [Rights]                        dc_rights
# @attr [Provenance]                    dc_provenance
# @attr [String]                        dc_description
# @attr [DublinCoreFormat]              dc_format
# @attr [DcmiType]                      dc_type
# @attr [Array<String>]                 dc_subject
# @attr [IsoDay]                        dcterms_dateAccepted
# @attr [IsoYear]                       dcterms_dateCopyright
#--
# === Schema.org Fields
#++
# @attr [Array<A11yFeature>]            s_accessibilityFeature
# @attr [Array<A11yControl>]            s_accessibilityControl
# @attr [Array<A11yHazard>]             s_accessibilityHazard
# @attr [Array<A11yAPI>]                s_accessibilityAPI
# @attr [String]                        s_accessibilitySummary
# @attr [Array<A11yAccessMode>]         s_accessMode
# @attr [Array<A11ySufficient>]         s_accessModeSufficient
#--
# === Periodical Fields
#++
# @attr [String]                        periodical_title
# @attr [Array<PublicationIdentifier>]  periodical_identifier
# @attr [String]                        periodical_series_position
#--
# === Remediation Fields
#++
# @attr [SourceType]                    rem_source
# @attr [Array<String>]                 rem_metadataSource
# @attr [Array<String>]                 rem_remediatedBy
# @attr [Boolean]                       rem_complete
# @attr [String]                        rem_coverage
# @attr [Array<RemediationType>]        rem_remediatedAspects
# @attr [TextQuality]                   rem_quality
# @attr [RemediationStatus]             rem_status
#
# @see https://app.swaggerhub.com/apis/bus/emma-federated-search-api/0.0.5#/MetadataCommonRecord                               Search API documentation
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/MetadataCommonRecord  JSON schema specification
#
# @see Search::Record::MetadataRecord    (schema superset)
# @see Ingest::Record::IngestionRecord   (duplicate schema)
# @see AwsS3::Message::SubmissionRequest (schema superset)
#
class Search::Record::MetadataCommonRecord < Search::Api::Record

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

    has_one   :emma_repository,                   EmmaRepository
    has_many  :emma_collection
    has_one   :emma_repositoryRecordId
    has_one   :emma_retrievalLink
    has_one   :emma_webPageLink
    has_one   :emma_lastRemediationDate,          IsoDay
    has_one   :emma_sortDate,                     IsoDay
    has_one   :emma_repositoryMetadataUpdateDate, IsoDay
    has_one   :emma_publicationDate,              IsoDay
    has_one   :emma_lastRemediationNote
    has_one   :emma_version
    has_one   :emma_workType,                     WorkType
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

    has_one   :periodical_title
    has_many  :periodical_identifier,             PublicationIdentifier
    has_one   :periodical_series_position

    has_one   :rem_source,                        SourceType
    has_many  :rem_metadataSource
    has_many  :rem_remediatedBy
    has_one   :rem_complete,                      Boolean
    has_one   :rem_coverage
    has_many  :rem_remediatedAspects,             RemediationType
    has_one   :rem_quality,                       TextQuality
    has_one   :rem_status,                        RemediationStatus

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Model, Hash, String, nil] src
  # @param [Hash, nil]                                   opt
  #
  def initialize(src, opt = nil)
    opt ||= {}
    super(src, **opt)
    normalize_data_fields!
  end

end

__loading_end(__FILE__)
