# app/records/search/record/metadata_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Record::MetadataRecord
#
# @attr [String]                        emma_recordId
# @attr [String]                        emma_titleId
#
# === Fields also defined in Search::Record::MetadataCommonRecord
#
# @attr [EmmaRepository]                emma_repository
# @attr [String]                        emma_collection
# @attr [String]                        emma_repositoryRecordId
# @attr [String]                        emma_retrievalLink # NOTE: URI
# @attr [IsoDate]                       emma_lastRemediationDate
# @attr [String]                        emma_lastRemediationNote
# @attr [String]                        emma_formatVersion
# @attr [Array<FormatFeature>]          emma_formatFeature
# @attr [String]                        dc_title
# @attr [Array<String>]                 dc_creator
# @attr [Array<PublicationIdentifier>]  dc_identifier
# @attr [String]                        dc_publisher
# @attr [Array<PublicationIdentifier>]  dc_relation
# @attr [String]                        dc_language # NOTE: not array
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
# NOTE: This duplicates:
# @see Search::Message::SearchRecord
#
# noinspection DuplicatedCode
class Search::Record::MetadataRecord < Search::Api::Record

  include Search::Shared::TitleMethods

  schema do
    attribute :emma_recordId,             String
    attribute :emma_titleId,              String
    attribute :emma_repository,           EmmaRepository
    attribute :emma_collection,           String
    attribute :emma_repositoryRecordId,   String
    attribute :emma_retrievalLink,        String
    attribute :emma_lastRemediationDate,  IsoDate
    attribute :emma_lastRemediationNote,  String
    attribute :emma_formatVersion,        String
    has_many  :emma_formatFeature,        FormatFeature
    attribute :dc_title,                  String
    has_many  :dc_creator,                String
    has_many  :dc_identifier,             PublicationIdentifier
    attribute :dc_publisher,              String
    has_many  :dc_relation,               PublicationIdentifier
    attribute :dc_language,               String
    attribute :dc_rights,                 Rights
    attribute :dc_provenance,             Provenance
    attribute :dc_description,            String
    attribute :dc_format,                 DublinCoreFormat
    attribute :dc_type,                   DcmiType
    has_many  :dc_subject,                String
    attribute :dcterms_dateAccepted,      IsoDate
    attribute :dcterms_dateCopyright,     IsoYear
    has_many  :s_accessibilityFeature,    A11yFeature
    has_many  :s_accessibilityControl,    A11yControl
    has_many  :s_accessibilityHazard,     A11yHazard
    has_many  :s_accessibilityAPI,        A11yAPI
    attribute :s_accessibilitySummary,    String
    has_many  :s_accessMode,              A11yAccessMode
    has_many  :s_accessModeSufficient,    A11ySufficient
  end

end

__loading_end(__FILE__)
