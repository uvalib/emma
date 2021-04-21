# app/services/aws_s3_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AwsS3Service::Common
#
module AwsS3Service::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  # @private
  #
  def self.included(base)
    base.send(:include, AwsS3Service::Definition)
  end

  include ApiService::Common
  include AwsS3Service::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The AWS S3 bucket associated with the item.
  #
  # @param [AwsS3::Message::SubmissionPackage, Upload, Hash, String, Symbol, nil] item
  # @param [Symbol, String, nil] deployment     Def: `#application_deployment`.
  #
  # @return [String]
  # @return [nil]
  #
  def bucket_for(item, deployment = nil)
    repository = Upload.repository_of(item)&.to_sym
    deployment = deployment&.to_sym || application_deployment
    S3_BUCKET.dig(repository, deployment) if EmmaRepository.valid?(repository)
  end

  # Generate an array of submission package identifiers (AWS S3 object keys).
  #
  # @param [AwsS3::Message::SubmissionPackage, Upload, Hash, String] item
  #
  # @return [String, nil]
  #
  def submission_id(item)
    # noinspection RubyYardReturnMatch
    case item
      when Upload, AwsS3::Message::SubmissionPackage
        item.submission_id
      when Hash
        item[:submission_id] || item['submission_id']
      when String
        item
      else
        Log.warn { "#{__method__}: unexpected: #{item.inspect}" }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get an S3 client instance.
  #
  # @param [Hash] opt                 Passed to Aws::S3::Client#initialize
  #
  # @return [Aws::S3::Client]
  #
  def s3_client(**opt)
    Aws::S3::Client.new(S3_OPTIONS.merge(opt))
  end

  # Get an S3 resource instance.
  #
  # @return [Aws::S3::Resource]
  #
  def s3_resource(**opt)
    opt[:client] ||= s3_client(opt)
    Aws::S3::Resource.new(S3_OPTIONS.merge(opt))
  end

  # Get an S3 bucket instance.
  #
  # @return [Aws::S3::Bucket]
  #
  def s3_bucket(bucket, **opt)
    s3_resource(**opt).bucket(bucket)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Upload an individual file to an AWS S3 bucket.
  #
  # @param [String, Aws::S3::Bucket]                 bucket
  # @param [String]                                  key
  # @param [AWS::S3::Object, String, StringIO, File] content
  # @param [Hash]                                    opt
  #
  # @option opt [Symbol]          :meth     Calling method for logging
  # @option opt [Aws::S3::Client] :client
  #
  # @return [String]                  Uploaded object key.
  # @return [nil]                     If the operation failed.
  #
  #--
  # noinspection RubyScope
  #++
  def api_put_file(bucket, key, content, **opt)
    client   = opt.delete(:client)
    client ||= (bucket.client if bucket.is_a?(Aws::S3::Bucket))
    client ||= s3_client(**opt)
    meth     = opt.delete(:meth) || calling_method
    params   = { bucket: bucket, key: key }
    # @type [Types::CopyObjectOutput, Types::PutObjectOutput] response
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
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String] key
  # @param [Hash]   opt               Passed to #get_object except for:
  #
  # @option opt [Symbol]          :meth     Calling method for logging
  # @option opt [Aws::S3::Client] :client
  #
  # @return [String]                  Content of requested file.
  # @return [nil]                     If the operation failed.
  #
  #--
  # noinspection RubyScope
  #++
  def api_get_file(bucket, key, **opt)
    client   = opt.delete(:client)
    client ||= (bucket.client if bucket.is_a?(Aws::S3::Bucket))
    client ||= s3_client(**opt)
    meth     = opt.delete(:meth) || calling_method
    params   = { bucket: bucket, key: key }
    # @type [Aws::S3::Types::GetObjectOutput] response
    response = client.get_object(params, opt)
    Log.debug { "#{meth}: AWS S3 response: #{response.inspect} "}
    response.body.read
  rescue StandardError => e
    @exception = e
    Log.warn { "#{meth}: AWS S3 failure: #{e.class}: #{e.message}" }
  end

  # Remove a single file from an AWS S3 bucket.
  #
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String] key
  # @param [Hash]   opt               Passed to #get_object except for:
  #
  # @option opt [Symbol]          :meth     Calling method for logging
  # @option opt [Aws::S3::Client] :client
  #
  # @return [String]                  Removed object key.
  # @return [nil]                     If the operation failed.
  #
  #--
  # noinspection RubyScope
  #++
  def api_delete_file(bucket, key, **opt)
    client   = opt.delete(:client)
    client ||= (bucket.client if bucket.is_a?(Aws::S3::Bucket))
    client ||= s3_client(**opt)
    meth     = opt.delete(:meth) || calling_method
    params   = { bucket: bucket, key: key }
    # @type [Aws::S3::Types::DeleteObjectOutput] response
    response = client.delete_object(params, opt)
    Log.debug { "#{meth}: AWS S3 response: #{response.inspect} "}
    key
  rescue StandardError => e
    @exception = e
    Log.warn { "#{meth}: AWS S3 failure: #{e.class}: #{e.message}" }
  end

  # List files (object keys) in an AWS S3 bucket.
  #
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String, nil] filter       All objects if blank, missing, or '*'.
  # @param [Hash]        opt          Passed to #list_objects_v2 except for:
  #
  # @option opt [Symbol]          :meth     Calling method for logging
  # @option opt [Aws::S3::Client] :client
  #
  # @return [Array<Aws::S3::Object>]
  #
  #--
  # noinspection RubyScope, RubyNilAnalysis
  #++
  def api_list_objects(bucket, filter = nil, **opt)
    __debug_items(binding)
    client   = opt.delete(:client)
    client ||= (bucket.client if bucket.is_a?(Aws::S3::Bucket))
    client ||= s3_client(**opt)
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
    # @type [Aws::S3::Types::ListObjectsV2Output] response
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
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String, nil]             filter
  # @param [Hash]                    opt      Passed to #api_list_objects.
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
  def api_list_object_keys(bucket, filter = nil, **opt)
    unless filter.blank? || (filter == '*') || filter.match?(/\.\*?$/)
      return [filter] if filter.remove(%r{^.*/}).include?('.')
    end
    api_list_objects(bucket, filter, **opt).map(&:key)
  end


end

__loading_end(__FILE__)
