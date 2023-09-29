# app/records/aws_s3/message/submission_request.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The data and metadata to submit a new remediated variant to a partner
# repository via an AWS bucket pickup location.
#
#--
# === Submission Fields
#++
# @attr [String]                        submission_id
#--
# === Fields not yet supported by the EMMA Unified Index
#++
# @attr [String]                        bib_series
# @attr [SeriesType]                    bib_seriesType
# @attr [String]                        bib_seriesPosition
#
# @see file:config/locales/records/upload.en.yml          *en.emma.upload.record.emma_data*
# @see file:config/locales/records/search.en.yml          *en.emma.search.record*
# @see file:app/assets/javascripts/feature/file-upload.js *EmmaData*
#
# @see AwsS3::Record::SubmissionRequest   (duplicate schema)
# @see Search::Record::MetadataRecord     (schema subset)
#
class AwsS3::Message::SubmissionRequest < AwsS3::Api::Message

  include AwsS3::Shared::CreatorMethods
  include AwsS3::Shared::DateMethods
  include AwsS3::Shared::IdentifierMethods
  include AwsS3::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from AwsS3::Record::SubmissionRequest

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The AWS S3 file object that is the subject of the submission.
  #
  # @type [Aws::S3::Object]
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
  # @param [AwsS3::Message::SubmissionRequest, Model, Hash] src
  # @param [Hash]                                           opt
  #
  # @option opt [Aws::S3::Object] :file   Override file for submission.
  #
  #--
  # noinspection RubyMismatchedVariableType
  #++
  def initialize(src, **opt)
    @file = @file_key = nil
    case src
      when AwsS3::Message::SubmissionRequest, AwsS3::Record::SubmissionRequest
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
      when AwsS3::Message::SubmissionRequest, AwsS3::Record::SubmissionRequest
        @file_key ||= src.file_key
      else
        @file_key ||= sid + File.extname(@file.key)
        data = remove_empty_values(data)
    end

    # Make sure that emma_recordId is given the same value that EMMA Unified
    # Ingest will generate.
    data[:emma_recordId] ||= Upload.record_id(data)

    super(data, **opt)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new SubmissionRequest unless *src* already is one.
  #
  # @param [AwsS3::Message::SubmissionRequest, Model, Hash] record
  #
  # @return [AwsS3::Message::SubmissionRequest]
  #
  def self.[](record)
    # noinspection RubyMismatchedReturnType
    record.is_a?(self) ? record : new(record)
  end

  # Normalize to an array of submission records.
  #
  # @param [AwsS3::Message::SubmissionRequest, Model, Hash, Array] records
  #
  # @return [Array<AwsS3::Message::SubmissionRequest>]
  #
  def self.array(records)
    Array.wrap(records).flatten.map { |record|
      self[record] if record.present?
    }.compact
  end

end

__loading_end(__FILE__)
