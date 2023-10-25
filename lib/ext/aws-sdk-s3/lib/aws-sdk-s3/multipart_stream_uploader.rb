# lib/ext/aws-sdk-s3/lib/aws-sdk-s3/multipart_stream_uploader.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for 'aws-sdk-s3'.

__loading_begin(__FILE__)

require 'aws-sdk-s3/client'

module Aws::S3

  if DEBUG_AWS

    # Overrides adding extra debugging around method calls.
    #
    module MultipartStreamUploaderDebug

      include Aws::S3::ExtensionDebugging

      # =======================================================================
      # :section: Aws::S3::MultipartStreamUploader overrides
      # =======================================================================

      public

      def initialize(options = {})
        start = timestamp
        super
          .tap { __ext_log(start, options) }
      rescue => e
        __ext_log(e)
        raise e
      end

      def upload(options = {}, &blk)
        start = timestamp
        super
          .tap { __ext_log(start, options) }
      rescue => e
        __ext_log(e)
        raise e
      end

      def initiate_upload(options)
        start = timestamp
        super
          .tap { __ext_log(start, options) }
      rescue => e
        __ext_log(e)
        raise e
      end

      def complete_upload(upload_id, parts, options)
        start = timestamp
        super
          .tap { __ext_log(start, upload_id, parts, options) }
      rescue => e
        __ext_log(e)
        raise e
      end

      def upload_parts(upload_id, options, &blk)
        start = timestamp
        super
          .tap { __ext_log(start, upload_id, options) }
      rescue => e
        __ext_log(e)
        raise e
      end

      def abort_upload(upload_id, options, errors)
        start = timestamp
        super
          .tap { __ext_log(start, upload_id, options, errors) }
      rescue => e
        __ext_log(e)
        raise e
      end

      def read_to_part_body(read_pipe)
        start = timestamp
        super
          .tap { __ext_log(start) { { '@tempfile': @tempfile } } }
      rescue => e
        __ext_log(e)
        raise e
      end

      def upload_in_threads(read_pipe, completed, options)
        start = timestamp
        super
          .tap { __ext_log(start, options) }
      rescue => e
        __ext_log(e)
        raise e
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Aws::S3::MultipartStreamUploader =>
         Aws::S3::MultipartStreamUploaderDebug if DEBUG_AWS

__loading_end(__FILE__)
