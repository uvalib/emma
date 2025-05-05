# app/services/aws_s3_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Service implementation methods.
#
module AwsS3Service::Common

  include ApiService::Common

  include AwsS3Service::Properties

  include AwsS3::Shared::AwsMethods

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
      raise request_error(config_term(:aws, :no_records)) if items.blank?
    else
      opt[:bucket] ||= bucket_for(repo || items.first)
      items = items.map { submission_id(_1) }.compact
      raise request_error(config_term(:aws, :no_sids)) if items.blank?
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
  # :section: AwsS3::Shared::AwsMethods overrides
  # ===========================================================================

  public

  # Get an S3 client instance.
  #
  # @param [Hash] opt                 Passed to Aws::S3::Client#initialize
  #
  # @return [Aws::S3::Client]
  #
  def s3_client(**opt)
    opt.reverse_merge!(S3_OPTIONS)
    super
  end

  # ===========================================================================
  # :section: AwsS3::Shared::AwsMethods overrides
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
    opt[:meth] ||= calling_method
    super
  rescue => error
    set_error(error)
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
    opt[:meth] ||= calling_method
    super
  rescue => error
    set_error(error)
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
    opt[:meth] ||= calling_method
    super
  rescue => error
    set_error(error)
  end

  # ===========================================================================
  # :section: AwsS3::Shared::AwsMethods overrides
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
    opt[:meth] ||= calling_method
    super
  rescue => error
    set_error(error)
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
