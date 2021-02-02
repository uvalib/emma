# lib/ext/aws-sdk-s3/lib/aws-sdk-s3/plugins.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for 'aws-sdk-s3'.

__loading_begin(__FILE__)

require 'aws-sdk-core'

module Aws

  if DEBUG_AWS

    # Overrides adding extra debugging around method calls.
    #
    module PluginHandlerDebug

      include Aws::S3::ExtensionDebugging

      MISSING = '---'

      # =======================================================================
      # :section: Seahorse::Client::Handler overrides
      # =======================================================================

      public

      def call(context)
        from_file    = context.http_request.body.respond_to?(:size)
        chunk_size   = from_file ? context.http_request.body.size : MISSING
        body_payload = context.operation.input[:payload_member] || MISSING
        start_time   = timestamp
        super
          .tap do
            __ext_log(start_time, context) do
              { size: chunk_size, payload: body_payload.class }
            end
          end
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

if DEBUG_AWS
  Seahorse::Client::Handler.descendants.each do |plugin_handler|
    override plugin_handler => Aws::PluginHandlerDebug
  end
end
