# app/records/aws_s3/record/submission_request.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Combines metadata and a reference to a file into a submission request for
# retrieval by a member repository.
#
#--
# === Submission Fields
#++
# @attr [String]                        submission_id
#--
# === Unified Index Fields
#++
# @attr [String]                        emma_recordId
# @attr [String]                        emma_titleId
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
# -attr [Array<A11yAPI>]                s_accessibilityAPI
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
# @attr [String]                        rem_source
# @attr [Array<String>]                 rem_metadataSource
# @attr [Array<String>]                 rem_remediatedBy
# @attr [Boolean]                       rem_complete
# @attr [String]                        rem_coverage
# @attr [Array<RemediationType>]        rem_remediatedAspects
# @attr [TextQuality]                   rem_quality
# @attr [RemediationStatus]             rem_status
#--
# === Fields not yet supported by the Unified Index
#++
# @attr [String]                        bib_series
# @attr [SeriesType]                    bib_seriesType
# @attr [String]                        bib_seriesPosition
# @attr [String]                        bib_version
#
# @see file:config/locales/records/upload.en.yml          *en.emma.upload.record.emma_data*
# @see file:config/locales/records/search.en.yml          *en.emma.search.record*
# @see file:app/assets/javascripts/feature/file-upload.js *EmmaData*
#
# @see AwsS3::Message::SubmissionRequest  (duplicate schema)
# @see Search::Record::MetadataRecord     (schema subset)
#
class AwsS3::Record::SubmissionRequest < AwsS3::Api::Record

  include AwsS3::Shared::CreatorMethods
  include AwsS3::Shared::DateMethods
  include AwsS3::Shared::IdentifierMethods
  include AwsS3::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do

    attribute :submission_id

    has_one   :emma_recordId
    has_one   :emma_titleId

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
    #has_many  :s_accessibilityAPI,                A11yAPI
    has_one   :s_accessibilitySummary
    has_many  :s_accessMode,                      A11yAccessMode
    has_many  :s_accessModeSufficient,            A11ySufficient

    has_one   :periodical_title
    has_many  :periodical_identifier,             PublicationIdentifier
    has_one   :periodical_series_position

    has_one   :rem_source
    has_many  :rem_metadataSource
    has_many  :rem_remediatedBy
    has_one   :rem_complete,                      Boolean
    has_one   :rem_coverage
    has_many  :rem_remediatedAspects,             RemediationType
    has_one   :rem_quality,                       TextQuality
    has_one   :rem_status,                        RemediationStatus

    has_one   :bib_series
    has_one   :bib_seriesType,                    SeriesType
    has_one   :bib_seriesPosition
    has_one   :bib_version

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The AWS S3 file object that is the subject of the submission.
  #
  # @type [Aws::S3::Object, nil]
  #
  attr_reader :file

  # The AWS object key for the submitted file.
  #
  # @type [String]
  #
  attr_reader :file_key

  # The AWS object key for the submission package.
  #
  # @type [String]
  #
  attr_reader :key

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [AwsS3::Record::SubmissionRequest, Model, Hash] src
  # @param [Hash, nil]                                     opt
  #
  # @option opt [Aws::S3::Object] :file   Override file for submission.
  #
  def initialize(src, opt = nil)
    opt ||= {}
    @file = @file_key = nil
    case src
      when AwsS3::Record::SubmissionRequest
        data  = src
        sid   = src.submission_id
        @file = src.file
      when Upload
        data  = src.emma_metadata
        sid   = src.submission_id
        @file = src.s3_object
        data  = data.merge(submission_id: sid)
      when Hash
        data  = src.symbolize_keys
        sid   = data[:submission_id]
        @file = data.delete(:file)
      else
        raise "#{self.class}: #{src.class} unexpected"
    end

    @key  = "#{sid}.xml"
    @file = opt[:file] || @file
    if @file.blank?
      raise "#{self.class}: no file specified"
    elsif !@file.is_a?(Aws::S3::Object)
      raise "#{self.class}: file class #{@file.class} unexpected"
    end

    case src
      when AwsS3::Record::SubmissionRequest
        @file_key ||= src.file_key
      else
        @file_key ||= sid + File.extname(@file.key)
        data = remove_empty_values(data)
    end

    # Make sure that emma_recordId is given the same value that index ingest
    # will generate.
    data[:emma_recordId] ||= Upload.record_id(data)

    super(data, **opt)
  end

end

__loading_end(__FILE__)
