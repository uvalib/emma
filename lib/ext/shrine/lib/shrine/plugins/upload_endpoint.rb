# lib/ext/shrine/lib/shrine/plugins/upload_endpoint.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions to the Shrine :upload_endpoint plugin.

__loading_begin(__FILE__)

require 'shrine/plugins/upload_endpoint'

class Shrine

  module UploadEndpointExt

    # =========================================================================
    # :section: Shrine::UploadEndpoint overrides
    # =========================================================================

    protected

    # Include :emma_data in the response which would normally only be the
    # contents of :file_data.
    #
    # @param [Shrine::UploadedFile]    uploaded_file
    # @param [ActionDispatch::Request] request
    #
    # @return [(Integer, Hash, Array<String>)]
    #
    # @see file:app/assets/javascripts/feature/download.js onFileUploadSuccess()
    #
    # This method overrides:
    # @see Shrine::UploadEndpoint#make_response
    #
    def make_response(uploaded_file, request)
      return super if @rack_response
      body = uploaded_file.data.merge(emma_data: uploaded_file.emma_metadata)
      body = { data: body, url: resolve_url(uploaded_file, request) } if @url
      body = body.to_json
      [200, { 'Content-Type' => UploadEndpoint::CONTENT_TYPE_JSON }, [body]]
    end

  end

  if DEBUG_SHRINE

    # Overrides adding extra debugging around method calls.
    #
    module UploadEndpointDebug

      include Shrine::ExtensionDebugging

      # Non-functional hints for RubyMine type checking.
      # :nocov:
      include Shrine::UploadEndpointExt unless ONLY_FOR_DOCUMENTATION
      # :nocov:

      # =======================================================================
      # :section: Shrine::UploadEndpoint overrides
      # =======================================================================

      public

      # call
      #
      # @param [Hash] env
      #
      # This method overrides:
      # @see Shrine::UploadEndpoint#call
      #
      def call(env)
        start = timestamp
        super
          .tap { |result| __ext_debug(start, "-> #{result.inspect}") }
      end

      # =======================================================================
      # :section: Shrine::UploadEndpoint overrides
      # =======================================================================

      protected

      # handle_request
      #
      # @param [ActionDispatch::Request] request
      #
      # @return [(Integer, Hash, Array<String>)]
      #
      # This method overrides:
      # @see Shrine::UploadEndpoint#handle_request
      #
      def handle_request(request)
        start = timestamp
        super
          .tap do |result|
            __ext_debug(start, "-> #{result.inspect}") { { request: request } }
          end
      end

      # get_io
      #
      # @param [ActionDispatch::Request] request
      #
      # @return [Shrine::RackFile]
      #
      # This method overrides:
      # @see Shrine::UploadEndpoint#get_io
      #
      def get_io(request)
        start = timestamp
        super
          .tap { |result| __ext_debug(start, "-> #{result.inspect}") }
      end

      # get_multipart_upload
      #
      # @param [ActionDispatch::Request] request
      #
      # @return [Shrine::RackFile]
      #
      # This method overrides:
      # @see Shrine::UploadEndpoint#get_io
      #
      def get_multipart_upload(request)
        start = timestamp
        super
          .tap { |result| __ext_debug(start, "-> #{result.inspect}") }
      end

      # get_context
      #
      # @param [ActionDispatch::Request] request
      #
      # @return [Hash]
      #
      # This method overrides:
      # @see Shrine::UploadEndpoint#get_context
      #
      def get_context(request)
        start = timestamp
        super
          .tap { |result| __ext_debug(start, "-> #{result.inspect}") }
      end

      # upload
      #
      # @param [Shrine::RackFile]        io
      # @param [Hash]                    context
      # @param [ActionDispatch::Request] request
      #
      # @return [Shrine::UploadedFile]
      #
      # This method overrides:
      # @see Shrine::UploadEndpoint#upload
      #
      def upload(io, context, request)
        start = timestamp
        super
          .tap do |result|
            __ext_debug(start, "-> #{result.inspect}") do
              { io: io, context: context, request: request }
            end
          end
      end

      # make_response
      #
      # @param [Shrine::UploadedFile, Hash] uploaded_file
      # @param [ActionDispatch::Request]    request
      #
      # @return [(Integer, Hash, Array<String>)]
      #
      # This method overrides:
      # @see Shrine::UploadEndpointExt#make_response
      #
      def make_response(uploaded_file, request)
        start = timestamp
        super
          .tap do |result|
            __ext_debug(start, "-> #{result.inspect}") do
              { uploaded_file: uploaded_file, request: request }
            end
          end
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Shrine::UploadEndpoint => Shrine::UploadEndpointExt
override Shrine::UploadEndpoint => Shrine::UploadEndpointDebug if DEBUG_SHRINE

__loading_end(__FILE__)
