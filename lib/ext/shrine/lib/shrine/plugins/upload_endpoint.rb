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
    # @return [Array<(Integer, Rack::Headers, Array<String>)>]
    #
    # @see file:javascripts/shared/uploader.js *onFileUploadSuccess()*
    #
    #--
    # noinspection RubyMismatchedReturnType
    #++
    def make_response(uploaded_file, request)
      return super if @rack_response
      body = uploaded_file.data.merge(emma_data: uploaded_file.emma_metadata)
      body = { data: body, url: resolve_url(uploaded_file, request) } if @url
      body = body.to_json
      hdrs = { 'Content-Type' => UploadEndpoint::CONTENT_TYPE_JSON }
      hdrs = Rack::Headers[hdrs] if Rack.release >= '3'
      hdrs['Cache-Control'] = 'no-store' unless hdrs.key?('Cache-Control')
      [200, hdrs, [body]]
    end

  end

  if DEBUG_SHRINE

    # Overrides adding extra debugging around method calls.
    #
    module UploadEndpointDebug

      include Shrine::ExtensionDebugging

      # Non-functional hints for RubyMine type checking.
      # :nocov:
      unless ONLY_FOR_DOCUMENTATION
        include Shrine::UploadEndpointExt
      end
      # :nocov:

      # =======================================================================
      # :section: Shrine::UploadEndpoint overrides
      # =======================================================================

      public

      # call
      #
      # @param [Hash] env
      #
      def call(env)
        start = timestamp
        super
          .tap { __ext_debug(start, "-> #{_1.inspect}") }
      end

      # =======================================================================
      # :section: Shrine::UploadEndpoint overrides
      # =======================================================================

      protected

      # handle_request
      #
      # @param [ActionDispatch::Request] request
      #
      # @return [Array<(Integer, Rack::Headers, Array<String>)>]
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
      def get_io(request)
        start = timestamp
        super
          .tap { __ext_debug(start, "-> #{_1.inspect}") }
      end

      # get_multipart_upload
      #
      # @param [ActionDispatch::Request] request
      #
      # @return [Shrine::RackFile]
      #
      def get_multipart_upload(request)
        start = timestamp
        super
          .tap { __ext_debug(start, "-> #{_1.inspect}") }
      end

      # get_context
      #
      # @param [ActionDispatch::Request] request
      #
      # @return [Hash]
      #
      def get_context(request)
        start = timestamp
        super
          .tap { __ext_debug(start, "-> #{_1.inspect}") }
      end

      # upload
      #
      # @param [Shrine::RackFile]        io
      # @param [Hash]                    context
      # @param [ActionDispatch::Request] request
      #
      # @return [Shrine::UploadedFile]
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
      # @return [Array<(Integer, Rack::Headers, Array<String>)>]
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
