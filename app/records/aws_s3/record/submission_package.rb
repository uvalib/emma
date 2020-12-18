# app/records/aws_s3/record/submission_package.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AwsS3::Record::SubmissionPackage
#
# @attr [String]                        submission_id
#
# == Fields from Search::Message::SearchRecord
#
# @attr [String]                        emma_recordId
# @attr [String]                        emma_titleId
# @attr [EmmaRepository]                emma_repository
# @attr [Array<String>]                 emma_collection
# @attr [String]                        emma_repositoryRecordId
# @attr [String]                        emma_retrievalLink
# @attr [String]                        emma_webPageLink
# @attr [IsoDate]                       emma_lastRemediationDate
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
# @attr [Array<A11yAccessMode>]         s_accessMode
# @attr [Array<A11ySufficient>]         s_accessModeSufficient
# @attr [String]                        s_accessibilitySummary
#
# == Fields not yet supported by the Unified Index
#
# @attr [String]                        bib_series
# @attr [SeriesType]                    bib_seriesType
# @attr [String]                        bib_seriesPosition
# @attr [String]                        bib_version
# @attr [String]                        rem_source
# @attr [Array<String>]                 rem_metadataSource
# @attr [Array<String>]                 rem_remediatedBy
# @attr [Boolean]                       rem_complete
# @attr [Array<String>]                 rem_coverage
# @attr [Array<String>]                 rem_remediation
# @attr [Array<TextQuality>]            rem_quality
# @attr [RemediationStatus]             rem_status
#
# @see "en.emma.upload.record.emma_data" (config/locales/records/upload.en.yml)
# @see "en.emma.search.fields" (config/locales/controllers/search.en.yml)
# @see EmmaData in app/assets/javascripts/feature/file-upload.js
#
class AwsS3::Record::SubmissionPackage < AwsS3::Api::Record

  include Emma::Common

  schema do

    attribute :submission_id

    # == Fields from Search::Message::SearchRecord

    has_one   :emma_recordId
    has_one   :emma_titleId
    has_one   :emma_repository,                   EmmaRepository
    has_many  :emma_collection
    has_one   :emma_repositoryRecordId
    has_one   :emma_retrievalLink
    has_one   :emma_webPageLink
    has_one   :emma_lastRemediationDate,          IsoDate
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
    has_many  :s_accessMode,                      A11yAccessMode
    has_many  :s_accessModeSufficient,            A11ySufficient
    has_one   :s_accessibilitySummary

    # == Fields not yet supported by the Unified Index

    has_one   :bib_series
    has_one   :bib_seriesType,                    SeriesType
    has_one   :bib_seriesPosition
    has_one   :bib_version
    has_one   :rem_source
    has_many  :rem_metadataSource
    has_many  :rem_remediatedBy
    has_one   :rem_complete,                      Boolean
    has_many  :rem_coverage
    has_many  :rem_remediation
    has_many  :rem_quality,                       TextQuality
    has_one   :rem_status,                        RemediationStatus

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
  # @param [AwsS3::Record::SubmissionPackage, Upload, Hash] src
  # @param [Hash]                                           opt
  #
  # @option opt [Aws::S3::Object] :file   Override file for submission.
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def initialize(src, **opt)
    @file = @file_key = nil
    case src
      when AwsS3::Record::SubmissionPackage
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
      when AwsS3::Record::SubmissionPackage
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  def remove_empty_values(item)
    case item
      when TrueClass, FalseClass
        item
      when Hash
        item.map { |k, v| [k, send(__method__, v)] }.to_h.compact.presence
      when Array
        item.map { |v| send(__method__, v) }.compact.presence
      when ModelHelper::EMPTY_VALUE
        nil
      else
        item.presence
    end
  end

end

__loading_end(__FILE__)
