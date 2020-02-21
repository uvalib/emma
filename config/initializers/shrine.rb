# config/initializers/shrine.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# @see https://shrinerb.com/docs/getting-started

require 'shrine'
require 'shrine/storage/file_system'
#require 'shrine/storage/s3' # Needs "gem 'aws-sdk-s3', '~> 1.14'"

UPLOAD_DIR = ENV.fetch('UPLOAD_DIR', 'storage/upload').freeze

Shrine.logger       = Log.logger
Shrine.logger.level = Log::DEBUG

Shrine.storages = {
  store: Shrine::Storage::FileSystem.new(UPLOAD_DIR),
  cache: Shrine::Storage::FileSystem.new("#{UPLOAD_DIR}_cache"),
}

Shrine.plugin :activerecord           # or :sequel
Shrine.plugin :cached_attachment_data # To retain the file across form redisplays.
Shrine.plugin :restore_cached_data    # Re-extract metadata when attaching a cached file.
Shrine.plugin :rack_file              # for non-Rails apps

Shrine.plugin :upload_endpoint        # For Uppy support via upload_endpoint.

Shrine.plugin :determine_mime_type,
              analyzer: :marcel,
              analyzer_options: { filename_fallback: true }

Shrine.plugin :validation
Shrine.plugin :validation_helpers
Shrine.plugin :remove_invalid

Shrine.plugin :instrumentation
