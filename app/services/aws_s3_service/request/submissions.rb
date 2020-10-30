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
  # @overload api_operation(op, *items, **opt)
  #   @param [Array<AwsS3::Message::SubmissionPackage, Upload, Hash>] items
  #   @param [Hash]               options
  #   @option opt [String]        bucket  Override bucket implied by *items*
  #
  # @overload api_operation(op, *sids, **opt)
  #   @param [Array<String>]      sids
  #   @param [Hash]               options
  #   @option opt [String,Symbol] repo    Used to determine S3 bucket.
  #   @option opt [String]        bucket  To specify S3 bucket.
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
  # @option opt [Aws::S3::Client] client
  #
  # @option opt [Symbol] meth         Calling method for logging
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
    meth   = opt.delete(:meth) || calling_method
    client = opt.delete(:client)
    client ||= Aws::S3::Client.new(opt.reverse_merge!(S3_OPTIONS))
    records.map { |record|
      # @type [AwsS3::Message::SubmissionPackage] record
      bkt = bucket || bucket_for(record)
      pkg = api_put_file(client, bkt, record.key, record.to_xml, meth: meth)
      obj = api_put_file(client, bkt, record.file_key, record.file, meth: meth)
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
  # @option opt [Aws::S3::Client] client
  #
  # @return [Hash{String=>String}]    Mapping of object key to related content.
  #
  # @see #api_get_file
  #
  def api_get(*sids, bucket:, atomic: true, **opt)
    raise 'no AWS S3 bucket'  if bucket.blank?
    raise 'no submission IDs' if sids.blank?
    meth   = opt.delete(:meth) || calling_method
    client = opt.delete(:client)
    client ||= Aws::S3::Client.new(opt.reverse_merge!(S3_OPTIONS))
    sids.flat_map { |sid|
      api_list_object_keys(client, bucket, sid, meth: meth).map do |key|
        content = api_get_file(client, bucket, key, meth: meth)
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
  # @option opt [Aws::S3::Client] client
  #
  # @return [Array<String>]           Object keys of deleted files.
  #
  # @see Aws::S3::Client#delete_objects
  #
  def api_delete(*sids, bucket:, atomic: true, **opt)
    raise 'no AWS S3 bucket'  if bucket.blank?
    raise 'no submission IDs' if sids.blank?
    meth   = opt.delete(:meth) || calling_method
    client = opt.delete(:client)
    client ||= Aws::S3::Client.new(opt.reverse_merge!(S3_OPTIONS))
    sids.flat_map { |sid|
      api_list_object_keys(client, bucket, sid, meth: meth).map do |key|
        api_delete_file(client, bucket, key, meth: meth).tap do |result|
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
  # @option opt [Aws::S3::Client] client
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
    meth   = opt.delete(:meth) || calling_method
    client = opt.delete(:client)
    client ||= Aws::S3::Client.new(opt.reverse_merge!(S3_OPTIONS))
    sids.map { |sid|
      [sid, api_list_objects(client, bucket, sid, meth: meth).map(&:key)]
    }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Upload an individual file to an AWS S3 bucket.
  #
  # @param [Aws::S3::Client]                         client
  # @param [String]                                  bucket
  # @param [String]                                  key
  # @param [AWS::S3::Object, String, StringIO, File] content
  # @param [Hash]                                    opt
  #
  # @option opt [Symbol] meth         Calling method for logging
  #
  # @return [String]                  Uploaded object key.
  # @return [nil]                     If the operation failed.
  #
  #--
  # noinspection RubyScope
  #++
  def api_put_file(client, bucket, key, content, **opt)
    # @type [Types::CopyObjectOutput, Types::PutObjectOutput] response
    meth     = opt.delete(:meth) || calling_method
    params   = { bucket: bucket, key: key }
    response =
      if content.is_a?(Aws::S3::Object)
        params[:copy_source] = "#{content.bucket_name}/#{content.key}"
        client.copy_object(params, opt)
      else
        params[:body] = content.is_a?(String) ? StringIO.new(content) : content
        client.put_object(params, opt)
      end
    Log.debug { "#{meth}: AWS S3 response: #{response.inspect} "}
    key
  rescue StandardError => e
    @exception = e
    Log.warn { "#{meth}: AWS S3 failure: #{e.class}: #{e.message}" }
  end

  # Download a single file from an AWS S3 bucket.
  #
  # @param [Aws::S3::Client] client
  # @param [String]          bucket
  # @param [String]          key
  # @param [Hash]            opt      Passed to #get_object except for:
  #
  # @option opt [Symbol] meth         Calling method for logging
  #
  # @return [String]                  Content of requested file.
  # @return [nil]                     If the operation failed.
  #
  #--
  # noinspection RubyScope
  #++
  def api_get_file(client, bucket, key, **opt)
    # @type [Aws::S3::Types::GetObjectOutput] response
    meth     = opt.delete(:meth) || calling_method
    params   = { bucket: bucket, key: key }
    response = client.get_object(params, opt)
    Log.debug { "#{meth}: AWS S3 response: #{response.inspect} "}
    response.body.read
  rescue StandardError => e
    @exception = e
    Log.warn { "#{meth}: AWS S3 failure: #{e.class}: #{e.message}" }
  end

  # Remove a single file from an AWS S3 bucket.
  #
  # @param [Aws::S3::Client] client
  # @param [String]          bucket
  # @param [String]          key
  # @param [Hash]            opt      Passed to #get_object except for:
  #
  # @option opt [Symbol] meth         Calling method for logging
  #
  # @return [String]                  Removed object key.
  # @return [nil]                     If the operation failed.
  #
  #--
  # noinspection RubyScope
  #++
  def api_delete_file(client, bucket, key, **opt)
    # @type [Aws::S3::Types::DeleteObjectOutput] response
    meth     = opt.delete(:meth) || calling_method
    params   = { bucket: bucket, key: key }
    response = client.delete_object(params, opt)
    Log.debug { "#{meth}: AWS S3 response: #{response.inspect} "}
    key
  rescue StandardError => e
    @exception = e
    Log.warn { "#{meth}: AWS S3 failure: #{e.class}: #{e.message}" }
  end

  # List files (object keys) in an AWS S3 bucket.
  #
  # @param [Aws::S3::Client] client
  # @param [String]          bucket
  # @param [String, nil]     filter   All objects if blank, missing, or '*'.
  # @param [Hash]            opt      Passed to #list_objects_v2 except for:
  #
  # @option opt [Symbol] meth         Calling method for logging
  #
  # @return [Array<Aws::S3::Object>]
  #
  #--
  # noinspection RubyScope, RubyNilAnalysis
  #++
  def api_list_objects(client, bucket, filter = nil, **opt)
    __debug_args(binding)
    # @type [Aws::S3::Types::ListObjectsV2Output] response
    meth   = opt.delete(:meth) || calling_method
    params = { bucket: bucket }
    filter =
      case filter.presence
        when nil     then nil # No filter means list all objects in the bucket.
        when '*'     then nil # An explicit request for all objects.
        when /\.$/   then filter
        when /\.\*$/ then filter.delete_suffix('*')
        else              "#{filter}."
      end
    response = client.list_objects_v2(params, **opt)
    result = Array.wrap(response.contents)
    result = result.select { |obj| obj.key.start_with?(filter) } if filter
    result
  rescue StandardError => e
    @exception = e
    Log.warn { "#{meth}: AWS S3 failure: #{e.class}: #{e.message}" }
    []
  end

  # Lookup matching AWS S3 object keys if "filter" appears to be a pattern and
  # not a specific filename and extension.
  #
  # @param [Aws::S3::Client] client
  # @param [String]          bucket
  # @param [String, nil]     filter
  # @param [Hash]            opt      Passed to #api_list_objects
  #
  # @return [Array<String>]
  #
  # == Usage Notes
  # This should only be used when transforming a list of key name patterns into
  # actual key names -- use #api_list_objects directly when checking on the
  # presence of the files themselves.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def api_list_object_keys(client, bucket, filter = nil, **opt)
    unless filter.blank? || (filter == '*') || filter.match?(/\.\*?$/)
      return [filter] if filter.remove(%r{^.*/}).include?('.')
    end
    api_list_objects(client, bucket, filter, **opt).map(&:key)
  end

end

__loading_end(__FILE__)
