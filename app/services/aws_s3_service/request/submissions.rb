# app/services/aws_s3_service/request/submissions.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AwsS3Service::Request::Submissions
#
module AwsS3Service::Request::Submissions

  include AwsS3Service::Common

  # ===========================================================================
  # :section: Member repository requests
  # ===========================================================================

  public

  # Uploads one or more submissions into AWS S3 for the creation of new entries
  # in the member repository.
  #
  # @param [Array<Upload, Hash>] records
  # @param [Hash] opt                 Passed to #put_records.
  #
  # @return [Array<String>]           Succeeded submissions.
  #
  def creation_request(*records, **opt)
    opt[:meth] ||= __method__
    records = records.flatten
    records.map! { |record| AwsS3::Message::SubmissionPackage.new(record) }
    put_records(*records, **opt)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Uploads one or more requests into AWS S3 for the modification of existing
  # member repository entries.
  #
  # @param [Array<Upload, Hash>] records
  # @param [Hash] opt                 Passed to #put_records.
  #
  # @return [Array<String>]           Succeeded submissions.
  #
  def modification_request(*records, **opt)
    opt[:meth] ||= __method__
    records = records.flatten
    records.map! { |record| AwsS3::Message::SubmissionPackage.new(record) } # TODO: Make modification requests
    put_records(*records, **opt)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Uploads one or more requests into AWS S3 for the modification of existing
  # member repository entries.
  #
  # @param [Array<Upload, Hash>] records
  # @param [Hash] opt                 Passed to #put_records.
  #
  # @return [Array<String>]           Succeeded submissions.
  #
  def removal_request(*records, **opt)
    opt[:meth] ||= __method__
    records = records.flatten
    records.map! { |record| AwsS3::Message::SubmissionPackage.new(record) } # TODO: Make removal requests
    put_records(*records, **opt)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Uploads one or more submissions into AWS S3.
  #
  # @param [Array<AwsS3::Message::SubmissionPackage>] items
  # @param [Hash] opt                 Passed to #api_create.
  #
  # @return [Array<String>]           Succeeded submissions.
  #
  def put_records(*items, **opt)
    items = items.flatten
    repo  = opt.delete(:repo)
    opt[:bucket] ||= bucket_for(repo || items.first)
    opt[:meth]   ||= __method__
    api_create(*items, **opt).map(&:submission_id)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Retrieves one or more submissions from AWS S3.
  #
  # @param [Array<AwsS3::Message::SubmissionPackage, Upload, Hash, String>] items
  # @param [Hash] opt                 Passed to #api_get via #api_operation.
  #
  # @return [Hash{String=>String}]    File contents.
  #
  # @see #api_operation
  #
  def get_records(*items, **opt)
    opt[:meth] ||= __method__
    api_operation(:api_get, *items, **opt)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Removes one or more submissions from AWS S3.
  #
  # @param [Array<AwsS3::Message::SubmissionPackage, Upload, Hash, String>] items
  # @param [Hash] opt                 Passed to #api_delete via #api_operation.
  #
  # @return [Array<String>]           Succeeded deletions.
  #
  # @see #api_operation
  #
  def delete_records(*items, **opt)
    opt[:meth] ||= __method__
    api_operation(:api_delete, *items, **opt)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Lists the files present in AWS S3 associated with one or more submissions.
  #
  # @param [Array<AwsS3::Message::SubmissionPackage, Upload, Hash, String>] items
  # @param [Hash] opt                 Passed to #api_list via #api_operation.
  #
  # @return [Hash{String=>Array}]     The objects for each submission key.
  #
  # @see #api_operation
  #
  def list_records(*items, **opt)
    __debug_args(binding)
    opt[:meth] ||= __method__
    api_operation(:api_list, *items, **opt)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # api_operation
  #
  # @param [Symbol] op                API method
  # @param [Array<AwsS3::Message::SubmissionPackage, Upload, Hash, String>] items
  # @param [Hash]   options           Passed to *op*.
  #
  # @return [*]                       Depends on *op*
  #
  # == Variations
  #
  # @overload api_operation(op, *items, **options)
  #   @param [Symbol]                                                 op
  #   @param [Array<AwsS3::Message::SubmissionPackage, Upload, Hash>] items
  #   @param [Hash]                                                   options
  #   @option options [String] :bucket  Override bucket implied by *items*
  #
  # @overload api_operation(op, *sids, **options)
  #   @param [Symbol]        op
  #   @param [Array<String>] sids
  #   @param [Hash]          options
  #   @option options [String,Symbol] :repo     Used to determine S3 bucket.
  #   @option options [String]        :bucket   To specify S3 bucket.
  #
  def api_operation(op, *items, **options)
    items = items.flatten
    sids  = items.map { |key| submission_id(key) }.compact
    repo  = options.delete(:repo)
    options[:bucket] ||= bucket_for(repo || items.first)
    send(op, *sids, **options)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Upload the submission file and content file related to each submission ID.
  #
  # @param [Array<AwsS3::Message::SubmissionPackage>] records
  # @param [String]  bucket
  # @param [Boolean] atomic
  # @param [Hash]    opt              Passed to Aws::S3::Client#initialize or:
  #
  # @option opt [Aws::S3::Client] :client
  # @option opt [Symbol]          :meth     Calling method for logging
  #
  # @return [Array<AwsS3::Message::SubmissionPackage>]  Submitted records.
  #
  # @see Aws::S3::Object#put
  #
  # OR USE THE API:
  # @see https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
  #
  def api_create(*records, bucket: nil, atomic: true, **opt)
    raise 'no records' if records.blank?
    opt[:meth]   ||= calling_method
    opt[:client] ||= s3_client(**opt.except(:meth))
    records.map { |record|
      # @type [AwsS3::Message::SubmissionPackage] record
      bkt = bucket || bucket_for(record)
      pkg = api_put_file(bkt, record.key, record.to_xml, **opt)
      obj = api_put_file(bkt, record.file_key, record.file, **opt)
      if pkg && obj
        record
      elsif atomic
        # TODO: clean up
        return []
      end
    }.compact
  end

  # Get the files associated with each submission ID.
  #
  # @param [Array<String>] sids
  # @param [String]        bucket
  # @param [Boolean]       atomic
  # @param [Hash]          opt        Passed to Aws::S3::Client#initialize or:
  #
  # @option opt [Aws::S3::Client] :client
  # @option opt [Symbol]          :meth     Calling method for logging
  #
  # @return [Hash{String=>String}]    Mapping of object key to related content.
  #
  # @see #api_get_file
  #
  def api_get(*sids, bucket:, atomic: true, **opt)
    raise 'no AWS S3 bucket'  if bucket.blank?
    raise 'no submission IDs' if sids.blank?
    opt[:meth]   ||= calling_method
    opt[:client] ||= s3_client(**opt.except(:meth))
    sids.flat_map { |sid|
      api_list_object_keys(bucket, sid, **opt).map do |key|
        content = api_get_file(bucket, key, **opt)
        return [] if atomic && content.blank?
        [key, content]
      end
    }.compact.to_h
  end

  # Remove the files associated with each submission ID.
  #
  # @param [Array<String>] sids
  # @param [String]        bucket
  # @param [Boolean]       atomic
  # @param [Hash]          opt        Passed to Aws::S3::Client#initialize or:
  #
  # @option opt [Aws::S3::Client] :client
  # @option opt [Symbol]          :meth     Calling method for logging
  #
  # @return [Array<String>]           Object keys of deleted files.
  #
  # @see Aws::S3::Client#delete_objects
  #
  def api_delete(*sids, bucket:, atomic: true, **opt)
    raise 'no AWS S3 bucket'  if bucket.blank?
    raise 'no submission IDs' if sids.blank?
    opt[:meth]   ||= calling_method
    opt[:client] ||= s3_client(**opt.except(:meth))
    sids.flat_map { |sid|
      api_list_object_keys(bucket, sid, **opt).map do |key|
        api_delete_file(bucket, key, **opt).tap do |result|
          return [] if atomic && result.blank?
        end
      end
    }.compact
  end

  # List the object keys associated with each submission ID.
  #
  # @param [Array<String>] sids
  # @param [String]        bucket
  # @param [Hash]          opt        Passed to Aws::S3::Client#initialize or:
  #
  # @option opt [Aws::S3::Client] :client
  # @option opt [Symbol]          :meth     Calling method for logging
  #
  # @return [Hash{String=>Array}]     Mapping of IDs and related object keys.
  #
  # @see #api_get_file
  #
  def api_list(*sids, bucket:, **opt)
    __debug_args(binding)
    raise 'no AWS S3 bucket'  if bucket.blank?
    raise 'no submission IDs' if sids.blank?
    opt.delete(:atomic) # Not used in this method.
    opt[:meth]   ||= calling_method
    opt[:client] ||= s3_client(**opt.except(:meth))
    sids.map { |sid|
      [sid, api_list_objects(bucket, sid, **opt).map(&:key)]
    }.to_h
  end

end

__loading_end(__FILE__)
