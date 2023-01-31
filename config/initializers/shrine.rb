# config/initializers/shrine.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for the Shrine gem.
#
# @see https://shrinerb.com/docs/getting-started
# @see https://shrinerb.com/rdoc/files/doc/design_md.html

# =============================================================================
# Logging
# =============================================================================

public

# Use cloud storage except for desktop development.
#
# Also avoid setting up AWS storage when running `rake assets:precompile` from
# Dockerfile.
#
# @type [Boolean]
#
SHRINE_CLOUD_STORAGE =
  ENV.fetch('SHRINE_CLOUD_STORAGE') {
    (application_deployed? || !development_build?) && rails_application?
  }.then { |setting|
    true?(setting)
  }

require 'shrine'
require 'shrine/storage/s3'          if SHRINE_CLOUD_STORAGE
require 'shrine/storage/file_system' unless SHRINE_CLOUD_STORAGE

# =============================================================================
# Logging
# =============================================================================

Shrine.logger       = Log.new(progname: 'SHRINE')
Shrine.logger.level = DEBUG_SHRINE ? Log::DEBUG : Log::INFO

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

=begin # TODO: Shrine backgrounding?
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

public

# There are four distinct sets of S3 buckets -- three to provide a pickup
# location for submission of remediated items back to member repositories
# (defined in AwsS3Service#S3_BUCKET) -- and the one for storage of Shrine
# uploads, which is defined here.
#
# For desktop-testing, local storage based on subdirectories within the Rails
# project is an option, but may be of limited use -- perhaps for unit testing.
#
# @see https://shrinerb.com/docs/storage/s3
# @see https://shrinerb.com/docs/storage/file-system
#
Shrine.storages = {

  store: 'upload',                    # Storage for completed uploads.
  cache: 'upload_cache'               # Initial upload destination.

}.tap do |storages|
  if SHRINE_CLOUD_STORAGE

    # Prepend a distinguishing prefix for desktop development.
    storages.transform_values! { |v| "rwl_#{v}" } unless application_deployed?

    # S3 options are kept in encrypted credentials but can be overridden by
    # environment variables.
    s3_options = {
      bucket:            AWS_BUCKET,
      region:            AWS_REGION,
      secret_access_key: AWS_SECRET_KEY,
      access_key_id:     AWS_ACCESS_KEY_ID,
    }.compact.reverse_merge(Rails.application.credentials.s3 || {})

    storages.transform_values! do |prefix|
      Shrine::Storage::S3.new(prefix: prefix, **s3_options)
    end

  else

    # File system location of the storage subdirectories.
    storage_dir = ENV.fetch('STORAGE_DIR', 'storage')

    storages.transform_values! do |subdir|
      Shrine::Storage::FileSystem.new("#{storage_dir}/#{subdir}")
    end

  end
end
