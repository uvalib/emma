# app/records/search/record/metadata_common_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Record::MetadataCommonRecord
#
# @attr [EmmaRepository]                emma_repository
# @attr [Array<String>]                 emma_collection
# @attr [String]                        emma_repositoryRecordId
# @attr [String]                        emma_retrievalLink
# @attr [String]                        emma_webPageLink
# @attr [IsoDate]                       emma_lastRemediationDate
# @attr [IsoDate]                       emma_sortDate
# @attr [IsoDate]                       emma_repositoryMetadataUpdateDate
# @attr [String]                        emma_lastRemediationNote
# @attr [String]                        emma_formatVersion
# @attr [Array<FormatFeature>]          emma_formatFeature
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
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.3#/MetadataCommonRecord                               Search API documentation
# @see https://app.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord  HTML schema documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3                                           JSON schema specification
#
# @see Search::Record::MetadataRecord (schema superset)
#
#--
# noinspection DuplicatedCode
#++
class Search::Record::MetadataCommonRecord < Search::Api::Record

  include Search::Shared::TitleMethods

  schema do
    has_one   :emma_repository,                   EmmaRepository
    has_many  :emma_collection
    has_one   :emma_repositoryRecordId
    has_one   :emma_retrievalLink
    has_one   :emma_webPageLink
    has_one   :emma_lastRemediationDate,          IsoDate
    has_one   :emma_sortDate,                     IsoDate
    has_one   :emma_repositoryMetadataUpdateDate, IsoDate
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
    has_one   :dcterms_dateAccepted,              IsoDate
    has_one   :dcterms_dateCopyright,             IsoYear
    has_many  :s_accessibilityFeature,            A11yFeature
    has_many  :s_accessibilityControl,            A11yControl
    has_many  :s_accessibilityHazard,             A11yHazard
    has_many  :s_accessibilityAPI,                A11yAPI
    has_one   :s_accessibilitySummary
    has_many  :s_accessMode,                      A11yAccessMode
    has_many  :s_accessModeSufficient,            A11ySufficient
  end

end

__loading_end(__FILE__)
