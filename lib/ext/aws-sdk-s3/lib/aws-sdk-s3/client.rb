# lib/ext/aws-sdk-s3/lib/aws-sdk-s3/client.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for 'aws-sdk-s3'.

__loading_begin(__FILE__)

require 'aws-sdk-s3/client'

module Aws::S3

  if DEBUG_AWS

    module ClientDebug

      include Aws::S3::ExtensionDebugging

      # =======================================================================
      # :section: Seahorse::Client::Base overrides
      # =======================================================================

      public

      def initialize(*args)
        start = timestamp
        super
          .tap { __ext_log(start, *args) }
      rescue => e
        __ext_log(e)
        raise e
      end

      def build_request(operation_name, params = {})
        start = timestamp
        super
          .tap { __ext_log(start, operation_name, params) }
      rescue => e
        __ext_log(e)
        raise e
      end

      # =======================================================================
      # :section: Aws::S3::Client overrides
      # =======================================================================

      public

      MONITOR_CLIENT_METHODS =
        Aws::S3::Client.instance_methods(false).excluding(:waiter_names)

      MONITOR_CLIENT_METHODS.each do |meth|
        define_method(meth) do |params = {}, options = {}, &block|
          start = timestamp
          super(params, options, &block)
            .tap { __ext_log(meth, start, params, options) }
        rescue => e
          __ext_log(e)
          raise e
        end
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Aws::S3::Client => Aws::S3::ClientDebug if DEBUG_AWS

__loading_end(__FILE__)
