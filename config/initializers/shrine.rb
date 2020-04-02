# config/initializers/shrine.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# @see https://shrinerb.com/docs/getting-started

require 'shrine'

# =============================================================================
# Logging
# =============================================================================

Shrine.logger       = Log.logger
Shrine.logger.level = Log::DEBUG

# =============================================================================
# Storage setup
# =============================================================================

if application_deployed?

  # == AWS S3 storage
  # There are four distinct S3 buckets -- one for EMMA repository storage and
  # three to provide a pickup locations for remediated items derived from
  # content acquired from the other repositories.
  #
  # 'emma-storage-*'      === S3 bucket for EMMA local storage ===
  #   '/upload/*'         Uploaded files.
  #   '/upload_cache/*'   Files being uploaded.
  #   '/repository/*'     Finalized "EMMA Repository" files.
  #   '/outbox/'
  #   '/outbox/bs'        Staging for items to be queued for Bookshare.
  #   '/outbox/ht'        Staging for items to be queued for HathiTrust.
  #   '/outbox/ia'        Staging for items to be queued for Internet Archive.
  #
  # 'emma-bs-queue-*'     === S3 bucket for Bookshare updates ===
  # 'emma-ht-queue-*'     === S3 bucket for HathiTrust updates ===
  # 'emma-ia-queue-*'     === S3 bucket for Internet Archive updates ===

  require 'shrine/storage/s3'

  S3_OPTIONS = {
    bucket:            'emma-storage-staging',
    region:            ENV['AWS_REGION'],
    secret_access_key: ENV['AWS_SECRET_KEY'],
    access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
  }.compact.reverse_merge(Rails.application.credentials.s3 || {})

  Shrine.storages = {
    store: Shrine::Storage::S3.new(prefix: 'upload',       **S3_OPTIONS),
    cache: Shrine::Storage::S3.new(prefix: 'upload_cache', **S3_OPTIONS),
  }

else

  # == Local storage
  # Local storage is for desktop-testing use, based on subdirectories within
  # the Rails project "/storage" directory.

  require 'shrine/storage/file_system'

  STORAGE_DIR = ENV.fetch('STORAGE_DIR', 'storage').freeze

  Shrine.storages = {
    store: Shrine::Storage::FileSystem.new("#{STORAGE_DIR}/upload"),
    cache: Shrine::Storage::FileSystem.new("#{STORAGE_DIR}/upload_cache"),
  }

end

# =============================================================================
# Plugins
# =============================================================================

Shrine.plugin :activerecord           # or :sequel
Shrine.plugin :cached_attachment_data # Retain the file across form redisplay.
Shrine.plugin :restore_cached_data    # Refresh metadata for cached files.
Shrine.plugin :rack_file              # for non-Rails apps

Shrine.plugin :upload_endpoint        # For Uppy support via upload_endpoint.

Shrine.plugin :determine_mime_type,
              analyzer: :marcel,
              analyzer_options: { filename_fallback: true }

Shrine.plugin :validation
Shrine.plugin :validation_helpers
Shrine.plugin :remove_invalid

Shrine.plugin :instrumentation
