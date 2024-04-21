# app/services/aws_s3_service/action/submissions.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AwsS3Service::Action::Submissions
#
module AwsS3Service::Action::Submissions

  include AwsS3Service::Common
  include AwsS3Service::Testing

  # ===========================================================================
  # :section: Partner repository requests
  # ===========================================================================

  public

  # Uploads one or more submissions into AWS S3 for the creation of new entries
  # in the partner repository.
  #
  # @param [Array<AwsS3::Message::SubmissionRequest, Model, Hash>] records
  # @param [Hash] opt                 Passed to #put_records.
  #
  # @return [AwsS3::Message::Response]
  #
  def creation_request(*records, **opt)
    opt[:meth] ||= __method__
    requested = AwsS3::Message::SubmissionRequest.array(records)
    succeeded = put_records(*requested, **opt)
    api_return(requested, succeeded)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Uploads one or more requests into AWS S3 for the modification of existing
  # partner repository entries.
  #
  # @param [Array<AwsS3::Message::ModificationRequest, Model, Hash>] records
  # @param [Hash] opt                 Passed to #put_records.
  #
  # @return [AwsS3::Message::Response]
  #
  def modification_request(*records, **opt)
    opt[:meth] ||= __method__
    requested = AwsS3::Message::ModificationRequest.array(records)
    succeeded = put_records(*requested, **opt)
    api_return(requested, succeeded)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Uploads one or more requests into AWS S3 for the removal of existing
  # partner repository entries.
  #
  # @param [Array<AwsS3::Message::RemovalRequest, Model, Hash>] records
  # @param [Hash] opt                 Passed to #put_records.
  #
  # @return [AwsS3::Message::Response]
  #
  def removal_request(*records, **opt)
    opt[:meth] ||= __method__
    requested = AwsS3::Message::RemovalRequest.array(records)
    succeeded = put_records(*requested, **opt)
    api_return(requested, succeeded)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # ===========================================================================
  # :section: Queue maintenance
  # ===========================================================================

  public

  # Remove request(s) from a partner repository queue.
  #
  # @param [Array<AwsS3::Message::SubmissionRequest, Model, String>] records
  # @param [Hash] opt                 Passed to #delete_records.
  #
  # @return [AwsS3::Message::Response]
  #
  def dequeue(*records, **opt)
    opt[:meth] ||= __method__
    succeeded = delete_records(*records, **opt)
    api_return(records, succeeded)
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
  # @param [Array<AwsS3::Message::SubmissionRequest>] items
  # @param [Hash] opt                 Passed to #aws_create.
  #
  # @return [Array<AwsS3::Message::SubmissionRequest>]  Submitted records.
  #
  def put_records(*items, **opt)
    opt[:meth] ||= __method__
    api(:aws_create, *items, **opt)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Retrieves one or more submissions from AWS S3.
  #
  # @param [Array<AwsS3::Message::SubmissionRequest,Model,Hash,String>] items
  # @param [Hash] opt                 Passed to #aws_get.
  #
  # @return [Hash{String=>String}]    File contents.
  #
  # @see #api_operation
  #
  def get_records(*items, **opt)
    opt[:meth] ||= __method__
    api(:aws_get, *items, **opt)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Removes one or more submissions from AWS S3.
  #
  # @param [Array<AwsS3::Message::SubmissionRequest,Model,Hash,String>] items
  # @param [Hash] opt                 Passed to #aws_delete.
  #
  # @return [Array<String>]           Succeeded deletions.
  #
  # @see #api_operation
  #
  def delete_records(*items, **opt)
    opt[:meth] ||= __method__
    api(:aws_delete, *items, **opt)
  end
    .tap do |method|
      add_api method => {
        # TODO: ?
      }
    end

  # Lists the files present in AWS S3 associated with one or more submissions.
  #
  # @param [Array<AwsS3::Message::SubmissionRequest,Model,Hash,String>] items
  # @param [Hash] opt                 Passed to #aws_list.
  #
  # @return [Hash{String=>Array}]     The objects for each submission key.
  #
  # @see #api_operation
  #
  def list_records(*items, **opt)
    __debug_items(binding)
    opt[:meth] ||= __method__
    api(:aws_list, *items, **opt)
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

  # Upload the submission file and content file related to each submission ID.
  #
  # @param [Array<AwsS3::Message::SubmissionRequest>] records
  # @param [String]  bucket
  # @param [Boolean] atomic
  # @param [Hash]    opt              Passed to Aws::S3::Client#initialize or:
  #
  # @option opt [Aws::S3::Client] :client
  # @option opt [Symbol]          :meth     Calling method for logging
  #
  # @raise [AwsS3Service::RequestError]     If bucket is invalid.
  #
  # @return [Array<AwsS3::Message::SubmissionRequest>]  Submitted records.
  #
  # @see Aws::S3::Object#put
  #
  # OR USE THE API:
  # @see https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
  #
  def aws_create(*records, bucket: nil, atomic: true, **opt)
    opt[:meth]   ||= calling_method
    opt[:client] ||= s3_client(**opt.except(:meth))
    result = []
    records.map do |record|
      bkt = bucket || bucket_for(record)
      pkg = aws_put_file(bkt, record.key, record.to_xml, **opt)
      if pkg && aws_put_file(bkt, record.file_key, record.file, **opt)
        result << record
      else
        aws_delete_file(bkt, record.key, **opt) if pkg
        if atomic
          result.each do |res|
            sid = submission_id(res)
            bkt = bucket || bucket_for(res)
            aws_delete(*sid, bucket: bkt, atomic: false, **opt)
          end
          return []
        end
      end
    end
    result
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
  # @see #aws_get_file
  #
  def aws_get(*sids, bucket:, atomic: true, **opt)
    opt[:meth]   ||= calling_method
    opt[:client] ||= s3_client(**opt.except(:meth))
    sids.flat_map { |sid|
      aws_list_object_keys(bucket, sid, **opt).map do |key|
        content = aws_get_file(bucket, key, **opt)
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
  def aws_delete(*sids, bucket:, atomic: true, **opt)
    opt[:meth]   ||= calling_method
    opt[:client] ||= s3_client(**opt.except(:meth))
    sids.flat_map { |sid|
      aws_list_object_keys(bucket, sid, **opt).map do |key|
        aws_delete_file(bucket, key, **opt).tap do |result|
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
  # @see #aws_get_file
  #
  def aws_list(*sids, bucket:, **opt)
    __debug_items(binding)
    opt.delete(:atomic) # Not used in this method.
    opt[:meth]   ||= calling_method
    opt[:client] ||= s3_client(**opt.except(:meth))
    sids.map { |sid|
      objects = aws_list_objects(bucket, sid, **opt)&.map(&:key) || []
      [sid, objects]
    }.to_h
  end

end

__loading_end(__FILE__)
