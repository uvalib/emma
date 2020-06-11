# config/initializers/shrine.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# @see https://shrinerb.com/docs/getting-started
# @see https://shrinerb.com/rdoc/files/doc/design_md.html

# Use cloud storage except for desktop development.
#
# Also avoid setting up AWS storage when running `rake assets:precompile` from
# Dockerfile.
#
# @type [Boolean]
#
CLOUD_STORAGE =
  (Rails.env.production? || application_deployed?) && rails_application?

require 'shrine'
require 'shrine/storage/s3'          if CLOUD_STORAGE
require 'shrine/storage/file_system' unless CLOUD_STORAGE

# =============================================================================
# Logging
# =============================================================================

Shrine.logger       = Log.logger
Shrine.logger.level = Log::DEBUG

# =============================================================================
# Plugins
#
# @see Shrine::Plugins::*
# @see https://shrinerb.com/docs/design#plugins
# =============================================================================

Shrine.plugin :activerecord           # ActiveRecord integration.
Shrine.plugin :instrumentation        # Internal event notifications.
Shrine.plugin :remove_invalid         # Auto-delete file of an invalid upload.
Shrine.plugin :upload_endpoint        # For Uppy support via upload_endpoint.
Shrine.plugin :validation             # Validation when attaching a file.
Shrine.plugin :validation_helpers     # Stock validations.

Shrine.plugin :determine_mime_type,
              analyzer:         :marcel,
              analyzer_options: { filename_fallback: true }

=begin
# =============================================================================
# Backgrounding
# =============================================================================

Shrine.plugin :backgrounding

Shrine::Attacher.promote_block do
  Attachment::PromoteJob.perform_later(record, name, file_data)
end

Shrine::Attacher.destroy_block do
  Attachment::DestroyJob.perform_later(data)
end
=end

# =============================================================================
# Storage setup
# =============================================================================

storages = {
  store: 'upload',                    # Storage for completed uploads.
  cache: 'upload_cache'               # Initial upload destination.
}

if CLOUD_STORAGE

  # === AWS S3 storage ===
  #
  # There are four distinct S3 buckets -- one for EMMA repository storage and
  # three to provide a pickup locations for remediated items derived from
  # content acquired from the other repositories.
  #
  # "emma-storage-*"      === S3 bucket for EMMA local storage ===
  #   "/upload/*"         Uploaded files.
  #   "/upload_cache/*"   Files being uploaded.
  #   "/repository/*"     Finalized "EMMA Repository" files.
  #
  # "emma-bs-queue-*"     === S3 bucket for Bookshare updates ===
  #   "/upload/*"         Items queued for Bookshare.
  #   "/upload_cache/*"   Staging for items to deliver to Bookshare.
  #
  # "emma-ht-queue-*"     === S3 bucket for HathiTrust updates ===
  #   "/upload/*"         Items queued for HathiTrust.
  #   "/upload_cache/*"   Staging for items to deliver to HathiTrust.
  #
  # "emma-ia-queue-*"     === S3 bucket for Internet Archive updates ===
  #   "/upload/*"         Items queued for Internet Archive.
  #   "/upload_cache/*"   Staging for items to deliver to Internet Archive.
  #
  # @see https://shrinerb.com/docs/storage/s3

  s3_buckets = {
    bookshare:       'emma-bs-queue-staging',
    hathiTrust:      'emma-ht-queue-staging',
    internetArchive: 'emma-ia-queue-staging'
  }

  # S3 options are kept in encrypted credentials but can be overridden by
  # environment variables.
  s3_options = {
    bucket:            ENV.fetch('AWS_BUCKET', 'emma-storage-staging'),
    region:            ENV.fetch('AWS_REGION', 'us-east-1'),
    secret_access_key: ENV['AWS_SECRET_KEY'],
    access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
  }.compact.reverse_merge(Rails.application.credentials.s3 || {})

  # Prepend a distinguishing prefix for development.
  storages.transform_values! { |v| "rwl_#{v}" } unless application_deployed?

  Shrine.storages =
    storages.transform_values do |subdir|
      Shrine::Storage::S3.new(prefix: subdir, **s3_options)
    end

  s3_buckets.each_pair do |repo, bucket|
    s3_options[:bucket] = bucket
    storages.each_pair do |name, subdir|
      Shrine.storages[:"#{name}_#{repo}"] =
        Shrine::Storage::S3.new(prefix: subdir, **s3_options)
    end
  end

else

  # === Local storage ===
  #
  # Local storage is for desktop-testing use, based on subdirectories within
  # the Rails project "/storage" directory.
  #
  # @see https://shrinerb.com/docs/storage/file-system

  storage_dir = ENV.fetch('STORAGE_DIR', 'storage')

  Shrine.storages =
    storages.transform_values do |subdir|
      Shrine::Storage::FileSystem.new("#{storage_dir}/#{subdir}")
    end

end
