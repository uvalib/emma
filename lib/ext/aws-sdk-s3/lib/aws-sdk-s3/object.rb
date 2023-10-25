# lib/ext/aws-sdk-s3/lib/aws-sdk-s3/object.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for 'aws-sdk-s3'.

__loading_begin(__FILE__)

require 'aws-sdk-s3/object'

module Aws::S3

  if DEBUG_AWS

    # Overrides adding extra debugging around method calls.
    #
    module ObjectDebug

      include Aws::S3::ExtensionDebugging

      # =======================================================================
      # :section: Aws::S3::Object overrides
      # =======================================================================

      public

      def load
        start = timestamp
        super
          .tap { __ext_log(start) }
      end

      # =======================================================================
      # :section: Aws::S3::Object overrides
      # =======================================================================

      public

      # Since all of these methods have the same signature, they can be
      # overridden in a loop.
      #
      # @type [Array<Symbol>]
      #
      MONITOR_OBJECT_METHODS = %i[
        exists?
        wait_until_exists
        wait_until_not_exists
        wait_until
        copy_from
        delete
        get
        initiate_multipart_upload
        put
        restore_object
      ]

      MONITOR_OBJECT_METHODS.each do |meth|
        define_method(meth) do |options = {}, &blk|
          start = timestamp
          super(options, &blk)
            .tap { __ext_log(meth, start, options) }
        end
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Aws::S3::Object => Aws::S3::ObjectDebug if DEBUG_AWS

__loading_end(__FILE__)
