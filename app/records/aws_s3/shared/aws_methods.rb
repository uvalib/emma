# app/records/aws_s3/shared/aws_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting communication with AWS S3.
#
module AwsS3::Shared::AwsMethods

  include AwsS3::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Allowable AWS S3 Client initializer parameters.
  #
  # @return [Array<Symbol>]
  #
  def client_params
    @client_params ||= Aws::S3::Client.new.config.to_h.keys
  end

  # Get an S3 client instance.
  #
  # @param [Hash] opt                 Passed to Aws::S3::Client#initialize
  #
  # @return [Aws::S3::Client]
  #
  # === Usage Notes
  # The including module is expected to override this method in order to
  # supply the appropriate AWS credentials.
  #
  def s3_client(**opt)
    rejected = opt.slice!(*client_params).except!(:meth).presence
    Log.debug { "#{__method__}: ignoring: #{rejected.inspect} " } if rejected
    Aws::S3::Client.new(opt)
  end

  # Get an S3 resource instance.
  #
  # @param [Hash] opt                 Passed to #extract_client!.
  #
  # @return [Aws::S3::Resource]
  #
  def s3_resource(**opt)
    client = extract_client!(opt)
    Aws::S3::Resource.new(client: client)
  end

  # Get an S3 bucket instance.
  #
  # @param [String] name              Bucket name.
  # @param [Hash]   opt               Passed to #s3_resource.
  #
  # @return [Aws::S3::Bucket]
  #
  def s3_bucket(name, **opt)
    s3_resource(**opt).bucket(name)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Download a single file from an AWS S3 bucket.
  #
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String]  key
  # @param [Boolean] fatal            If *false*, only log exceptions.
  # @param [Hash]    opt              Passed to #get_object except for:
  #
  # @option opt [Symbol]          :meth     Calling method for logging
  # @option opt [Aws::S3::Client] :client
  #
  # @return [String]                  Content of requested file.
  # @return [nil]                     If the operation failed.
  #
  def aws_get_file(bucket, key, fatal: true, **opt)
    meth   = opt.delete(:meth) || calling_method
    client = extract_client!(opt, bucket)
    params = { bucket: bucket, key: key }
    # @type [Aws::S3::Types::GetObjectOutput]
    result = client.get_object(params, opt)
    Log.debug { "#{meth}: AWS S3 response: #{result.inspect}" }
    result.body.read
  rescue => error
    Log.warn { "#{meth}: AWS S3 get fail: #{error.class}: #{error.message}" }
    raise error if fatal
  end

  # Upload an individual file to an AWS S3 bucket.
  #
  # @param [String, Aws::S3::Bucket]                 bucket
  # @param [String]                                  key
  # @param [Aws::S3::Object, String, StringIO, File] content
  # @param [Boolean]                                 fatal
  # @param [Hash]                                    opt
  #
  # @option opt [Symbol]          :meth     Calling method for logging
  # @option opt [Aws::S3::Client] :client
  #
  # @return [String]                  Uploaded object key.
  # @return [nil]                     If the operation failed.
  #
  def aws_put_file(bucket, key, content, fatal: true, **opt)
    meth   = opt.delete(:meth) || calling_method
    client = extract_client!(opt, bucket)
    params = { bucket: bucket, key: key }
    # @type [Types::CopyObjectOutput, Types::PutObjectOutput]
    result =
      if content.is_a?(Aws::S3::Object)
        params[:copy_source] = "#{content.bucket_name}/#{content.key}"
        client.copy_object(params, opt)
      else
        # noinspection xRubyMismatchedArgumentType
        params[:body] = content.is_a?(String) ? StringIO.new(content) : content
        client.put_object(params, opt)
      end
    Log.debug { "#{meth}: AWS S3 response: #{result.inspect} " }
    key
  rescue => error
    Log.warn { "#{meth}: AWS S3 put fail: #{error.class}: #{error.message}" }
    raise error if fatal
  end

  # Remove a single file from an AWS S3 bucket.
  #
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String]  key
  # @param [Boolean] fatal            If *false*, only log exceptions.
  # @param [Hash]    opt              Passed to #get_object except for:
  #
  # @option opt [Symbol]          :meth     Calling method for logging
  # @option opt [Aws::S3::Client] :client
  #
  # @return [String]                  Removed object key.
  # @return [nil]                     If the operation failed.
  #
  def aws_delete_file(bucket, key, fatal: true, **opt)
    meth   = opt.delete(:meth) || calling_method
    client = extract_client!(opt, bucket)
    params = { bucket: bucket, key: key }
    # @type [Aws::S3::Types::DeleteObjectOutput]
    result = client.delete_object(params, opt)
    Log.debug { "#{meth}: AWS S3 response: #{result.inspect}" }
    key
  rescue => error
    Log.warn { "#{meth}: AWS S3 del fail: #{error.class}: #{error.message}" }
    raise error if fatal
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # List files (object keys) in an AWS S3 bucket.
  #
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String, nil] filter       All objects if blank, missing, or '*'.
  # @param [Boolean]     fatal        If *false*, only log exceptions.
  # @param [Hash]        opt          Passed to #list_objects_v2 except for:
  #
  # @option opt [Symbol]          :meth     Calling method for logging
  # @option opt [Aws::S3::Client] :client
  #
  # @return [Array<Aws::S3::Object>]
  # @return [nil]                     If the operation failed.
  #
  def aws_list_objects(bucket, filter = nil, fatal: true, **opt)
    meth   = opt.delete(:meth) || calling_method
    client = extract_client!(opt, bucket)
    params = { bucket: bucket }
    filter =
      case filter.presence
        when nil     then nil # No filter means list all objects in the bucket.
        when '*'     then nil # An explicit request for all objects.
        when /\.$/   then filter
        when /\.\*$/ then filter.delete_suffix('*')
        else              "#{filter}."
      end
    # @type [Aws::S3::Types::ListObjectsV2Output]
    resp   = client.list_objects_v2(params, **opt)
    result = Array.wrap(resp.contents)
    filter ? result.select { |obj| obj.key.start_with?(filter) } : result
  rescue => error
    Log.warn { "#{meth}: AWS S3 failure: #{error.class}: #{error.message}" }
    raise error if fatal
  end

  # Lookup matching AWS S3 object keys if "filter" appears to be a pattern and
  # not a specific filename and extension.
  #
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String, nil]             filter
  # @param [Hash]                    opt      Passed to #aws_list_objects.
  #
  # @return [Array<String>]
  #
  # === Usage Notes
  # This should only be used when transforming a list of key name patterns into
  # actual key names -- use #aws_list_objects directly when checking on the
  # presence of the files themselves.
  #
  def aws_list_object_keys(bucket, filter = nil, **opt)
    unless filter.blank? || (filter == '*') || filter.match?(/\.\*?$/)
      return [filter] if filter.remove(%r{^.*/}).include?('.')
    end
    aws_list_objects(bucket, filter, **opt)&.map(&:key) || []
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Extract :client from *opt*, or from *bucket*, or create a new client.
  #
  # @param [Hash] opt
  # @param [any, nil] bucket
  #
  # @return [Aws::S3::Client]
  #
  def extract_client!(opt, bucket = nil)
    bucket_client = (bucket.client if bucket.is_a?(Aws::S3::Bucket))
    opt.delete(:client) || bucket_client || s3_client(**opt)
  end

end

__loading_end(__FILE__)
