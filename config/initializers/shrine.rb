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

  require 'shrine/storage/s3'

  s3_options = Rails.application.credential.s3

  Shrine.storages = {
    store: Shrine::Storage::S3.new(**s3_options),
    cache: Shrine::Storage::S3.new(prefix: 'cache', **s3_options),
  }

=begin
  Shrine.plugin :presign_endpoint,
    presign_options: -> (request) do
      # Uppy will send the "filename" and "type" query parameters.
      params = request.params
      file   = params['filename'] # Uploaded file.
      type   = params['type']     # Default: "application/octet-stream"
      max    = ENV.fetch('MAX_UPLOAD_BYTES', 10.megabytes).to_i
      {
        content_disposition:  ContentDisposition.inline(file),
        content_type:         type,
        content_length_range: 0..max,
      }
    end
=end

else

  # == Local storage

  require 'shrine/storage/file_system'

  UPLOAD_DIR = ENV.fetch('UPLOAD_DIR', 'storage/upload').freeze

  Shrine.storages = {
    store: Shrine::Storage::FileSystem.new(UPLOAD_DIR),
    cache: Shrine::Storage::FileSystem.new("#{UPLOAD_DIR}_cache"),
  }

end

# =============================================================================
# Plugins
# =============================================================================

Shrine.plugin :activerecord           # or :sequel
Shrine.plugin :cached_attachment_data # Retain the file across form redisplays.
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
