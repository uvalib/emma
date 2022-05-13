# app/services/aws_s3_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AwsS3Service::Properties
#
module AwsS3Service::Properties

  include ApiService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values from config/locales/service.en.yml
  #
  # @type [Hash{Symbol=>Any}]
  #
  AWS_S3_CONFIG = i18n_erb('emma.service.aws_s3').deep_freeze

  # There are two S3 buckets for each member repository used to queue
  # submissions and two S3 buckets for EMMA which include storage used by
  # Shrine.
  #
  # "emma-storage-production"   EMMA uploads (et. al.)
  # "emma-storage-staging"      Development EMMA uploads
  #
  # "emma-bs-queue-production"  Submissions to Bookshare
  # "emma-bs-queue-staging"     Test submissions to Bookshare
  #
  # "emma-ht-queue-production"  Submissions to HathiTrust
  # "emma-ht-queue-staging"     Test submissions to HathiTrust
  #
  # "emma-ia-queue-production"  Submissions to Internet Archive
  # "emma-ia-queue-staging"     Test submissions to Internet Archive
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String}}]
  #
  S3_BUCKET =
    Api::Common::REPOSITORY.transform_values { |property|
      key  = property[:symbol]
      name = key ? "#{key}-queue" : 'storage'
      %i[production staging].map { |deployment|
        [deployment, "emma-#{name}-#{deployment}"]
      }.to_h
    }.deep_freeze

  # A list of the member repositories.
  #
  # @type [Array<Symbol>]
  #
  # @note Currently unused
  #
  MEMBER_REPOSITORIES = (S3_BUCKET.keys - %i[emma]).freeze

  # S3 options are kept in encrypted credentials but can be overridden by
  # environment variables.
  #
  # @type [Hash{Symbol=>String}]
  #
  S3_OPTIONS = {
    region:            AWS_REGION,
    secret_access_key: AWS_SECRET_KEY,
    access_key_id:     AWS_ACCESS_KEY_ID,
  }.compact
    .reverse_merge(Rails.application.credentials.s3 || {})
    .except(:bucket)
    .deep_freeze

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # The URL for the API connection.
  #
  # @return [String]
  #
  def base_url
    not_implemented 'unused for Aws::S3'
  end

  # The URL for the API connection as a URI.
  #
  # @return [URI::Generic]
  #
  def base_uri
    not_implemented 'unused for Aws::S3'
  end

  # Federated AwsS3 API key.
  #
  # @return [nil]
  #
  def api_key
    not_implemented 'unused for Aws::S3'
  end

  # API version is not a part of request URLs.
  #
  # @return [nil]
  #
  def api_version
    not_implemented 'unused for Aws::S3'
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
