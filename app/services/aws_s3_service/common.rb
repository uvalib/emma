# app/services/aws_s3_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AwsS3Service::Common
#
module AwsS3Service::Common

  include ApiService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, AwsS3Service::Definition)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # TODO: from config/initializers/shrine.rb - should probably relocate

  S3_BUCKET = {
    bookshare:       'bs',
    hathiTrust:      'ht',
    internetArchive: 'ia',
  }.transform_values { |repo_marker|
    production = Rails.env.production? && application_deployed?
    target     = production ? 'production' : 'staging'
    "emma-#{repo_marker}-queue-#{target}"
  }.deep_freeze

  S3_OPTIONS = {
    region:            AWS_REGION,
    secret_access_key: AWS_SECRET_KEY,
    access_key_id:     AWS_ACCESS_KEY_ID,
  }.compact
    .reverse_merge(Rails.application.credentials.s3 || {})
    .except(:bucket)
    .deep_freeze

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  public

  # The URL for the API connection.
  #
  # @return [String]
  #
  def base_url
    raise 'Unused for AwsS3'
  end

  # The URL for the API connection as a URI.
  #
  # @return [URI::Generic]
  #
  def base_uri
    raise 'Unused for AwsS3'
  end

  # Federated AwsS3 API key.
  #
  # @return [String]
  #
  def api_key
    raise 'Unused for AwsS3'
  end

  # API version is not a part of request URLs.
  #
  # @return [nil]
  #
  def api_version
    raise 'Unused for AwsS3'
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The AWS S3 bucket associated with the item.
  #
  # @param [AwsS3::Message::SubmissionPackage, Upload, Hash, String, Symbol, nil] item
  #
  # @return [String]
  # @return [nil]
  #
  def bucket_for(item)
    repo = Upload.repository_of(item)
    if repo && EmmaRepository.valid?(repo)
      S3_BUCKET[repo.to_sym]
    elsif item.is_a?(String) || item.is_a?(Symbol)
      item.to_s if S3_BUCKET.values.include?(item.to_s)
    end
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
      when AwsS3::Message::SubmissionPackage, Upload
        item.submission_id
      when Hash
        item[:submission_id] || item['submission_id']
      when String
        item
      else
        Log.warn { "#{__method__}: unexpected: #{item.inspect}" }
    end
  end

end

__loading_end(__FILE__)
