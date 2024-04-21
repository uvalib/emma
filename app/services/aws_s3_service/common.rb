# app/services/aws_s3_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AwsS3Service::Common
#
module AwsS3Service::Common

  include ApiService::Common

  include AwsS3Service::Properties

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  public

  # Get data from the API.
  #
  # @param [Symbol] operation         API method
  # @param [Array<AwsS3::Message::SubmissionRequest,Model,Hash,String>] items
  # @param [Hash]   opt               Passed to *operation*.
  #
  # @raise [AwsS3Service::RequestError]
  #
  # @return [any]                     Depends on *operation*.
  #
  #--
  # === Variations
  #++
  #
  # @overload api(operation, *items, **opt)
  #   @param [Symbol]        operation
  #   @param [Array<AwsS3::Message::SubmissionRequest,Model,Hash>] items
  #   @param [Hash]          opt
  #   @option opt [String] :bucket  Override bucket implied by *items*
  #
  # @overload api(operation, *sids, **opt)
  #   @param [Symbol]        operation
  #   @param [Array<String>] sids
  #   @param [Hash]          opt
  #   @option opt [String,Symbol] :repo     Used to determine S3 bucket.
  #   @option opt [String]        :bucket   To specify S3 bucket.
  #
  # === Usage Notes
  # Clears and/or sets @exception as a side-effect.
  #
  #--
  # noinspection RubyScope, RubyMismatchedArgumentType
  #++
  def api(operation, *items, **opt)
    clear_error
    error = nil

    # Set internal options from parameters or service options.
    local        = opt.extract!(:meth, *SERVICE_OPT)
    no_exception = local[:no_exception] || options[:no_exception]
    fatal        = local[:fatal]        || options[:fatal] || !no_exception
    meth         = local[:meth]         || calling_method

    repo  = opt.delete(:repo)
    items = items.flatten
    if operation == :aws_create
      raise request_error(config_text(:aws, :no_records)) if items.blank?
    else
      opt[:bucket] ||= bucket_for(repo || items.first)
      items = items.map { |key| submission_id(key) }.compact
      raise request_error(config_text(:aws, :no_sids)) if items.blank?
    end
    send(operation, *items, **opt)

  rescue => error
    set_error(error)

  ensure
    __debug_api_response(error: error)
    log_exception(error, meth: meth) if error
    clear_error                      if no_exception
    raise exception                  if exception && fatal
  end

  # Construct a message to be returned from the method that executed :api.
  # This provides a uniform call for initializing the object with information
  # needed to build the object to return, including error information.
  #
  # @param [Array<AwsS3::Message::SubmissionRequest,Model,String>] records
  # @param [Array<AwsS3::Message::SubmissionRequest,String>]       succeeded
  # @param [Hash]                                                  opt
  #
  # @return [AwsS3::Message::Response]
  #
  def api_return(records, succeeded, **opt)
    AwsS3::Message::Response.new(records, succeeded, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The AWS S3 bucket associated with the item.
  #
  # @param [AwsS3::Message::SubmissionRequest, Model, Hash, String, Symbol, nil] item
  # @param [Symbol, String, nil] deployment     Def: `#aws_deployment`.
  #
  # @raise [AwsS3Service::RequestError]
  #
  # @return [String]
  #
  def bucket_for(item, deployment = nil)
    repository = Upload.repository_value(item)&.to_sym
    deployment = deployment&.to_sym || aws_deployment
    S3_BUCKET.dig(repository, deployment).tap do |bucket|
      unless bucket
        if EmmaRepository.valid?(repository)
          raise request_error("no bucket for deployment #{deployment.inspect}")
        else
          raise request_error("no repository for #{item.inspect}")
        end
      end
    end
  end

  # Generate an array of submission package identifiers (AWS S3 object keys).
  #
  # @param [AwsS3::Message::SubmissionRequest, Model, Hash, String] item
  #
  # @return [String, nil]
  #
  def submission_id(item)
    # noinspection RubyMismatchedReturnType
    case item
      when Upload, AwsS3::Message::SubmissionRequest
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
  def s3_client(**opt)
    opt.slice!(*client_params) if opt.present?
    Aws::S3::Client.new(S3_OPTIONS.merge(opt))
  end

  # Get an S3 resource instance.
  #
  # @param [Hash] opt                       Passed to #s3_client except for:
  #
  # @option opt [Aws::S3::Client] :client   Used rather than creating a new one
  #
  # @return [Aws::S3::Resource]
  #
  def s3_resource(**opt)
    client = opt[:client] || s3_client(**opt)
    Aws::S3::Resource.new(client: client)
  end

  # Get an S3 bucket instance.
  #
  # @param [String] bucket                  Bucket name.
  # @param [Hash]   opt                     Passed to #s3_resource except for:
  #
  # @option opt [Aws::S3::Client] :client   Used rather than creating a new one
  #
  # @return [Aws::S3::Bucket]
  #
  def s3_bucket(bucket, **opt)
    s3_resource(**opt).bucket(bucket)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Upload an individual file to an AWS S3 bucket.
  #
  # @param [String, Aws::S3::Bucket]                 bucket
  # @param [String]                                  key
  # @param [Aws::S3::Object, String, StringIO, File] content
  # @param [Hash]                                    opt
  #
  # @option opt [Symbol]          :meth     Calling method for logging
  # @option opt [Aws::S3::Client] :client
  #
  # @return [String]                  Uploaded object key.
  # @return [nil]                     If the operation failed.
  #
  def aws_put_file(bucket, key, content, **opt)
    meth     = opt.delete(:meth) || calling_method
    client   = opt.delete(:client)
    client ||= (bucket.client if bucket.is_a?(Aws::S3::Bucket))
    client ||= s3_client(**opt)
    params   = { bucket: bucket, key: key }
    # @type [Types::CopyObjectOutput, Types::PutObjectOutput] response
    response =
      if content.is_a?(Aws::S3::Object)
        params[:copy_source] = "#{content.bucket_name}/#{content.key}"
        client.copy_object(params, opt)
      else
        # noinspection RubyMismatchedArgumentType
        params[:body] = content.is_a?(String) ? StringIO.new(content) : content
        client.put_object(params, opt)
      end
    Log.debug { "#{meth}: AWS S3 response: #{response.inspect} " }
    key
  rescue => error
    set_error(error)
    # noinspection RubyScope
    Log.warn { "#{meth}: AWS S3 failure: #{error.class}: #{error.message}" }
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
  def aws_get_file(bucket, key, **opt)
    meth     = opt.delete(:meth) || calling_method
    client   = opt.delete(:client)
    client ||= (bucket.client if bucket.is_a?(Aws::S3::Bucket))
    client ||= s3_client(**opt)
    params   = { bucket: bucket, key: key }
    # @type [Aws::S3::Types::GetObjectOutput] response
    response = client.get_object(params, opt)
    Log.debug { "#{meth}: AWS S3 response: #{response.inspect}" }
    response.body.read
  rescue => error
    set_error(error)
    # noinspection RubyScope
    Log.warn { "#{meth}: AWS S3 failure: #{error.class}: #{error.message}" }
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
  def aws_delete_file(bucket, key, **opt)
    meth     = opt.delete(:meth) || calling_method
    client   = opt.delete(:client)
    client ||= (bucket.client if bucket.is_a?(Aws::S3::Bucket))
    client ||= s3_client(**opt)
    params   = { bucket: bucket, key: key }
    # @type [Aws::S3::Types::DeleteObjectOutput] response
    response = client.delete_object(params, opt)
    Log.debug { "#{meth}: AWS S3 response: #{response.inspect}" }
    key
  rescue => error
    set_error(error)
    # noinspection RubyScope
    Log.warn { "#{meth}: AWS S3 failure: #{error.class}: #{error.message}" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  # @return [nil]                     If the operation failed.
  #
  def aws_list_objects(bucket, filter = nil, **opt)
    __debug_items(binding)
    meth     = opt.delete(:meth) || calling_method
    client   = opt.delete(:client)
    client ||= (bucket.client if bucket.is_a?(Aws::S3::Bucket))
    client ||= s3_client(**opt)
    params   = { bucket: bucket }
    filter   =
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
    filter ? result.select { |obj| obj.key.start_with?(filter) } : result
  rescue => error
    set_error(error)
    # noinspection RubyScope
    Log.warn { "#{meth}: AWS S3 failure: #{error.class}: #{error.message}" }
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

  private

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.include(AwsS3Service::Definition)
  end

end

__loading_end(__FILE__)
