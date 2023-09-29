# app/records/aws_s3/record/submission_request.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Combines metadata and a reference to a file into a submission request for
# retrieval by a partner repository.
#
#--
# === Submission Fields
#++
# @attr [String] submission_id
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

    all_from Search::Record::MetadataRecord

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
    # noinspection RubyMismatchedVariableType
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

    # Make sure that emma_recordId is given the same value that EMMA Unified
    # Ingest will generate.
    data[:emma_recordId] ||= Upload.record_id(data)

    super(data, **opt)
  end

end

__loading_end(__FILE__)
