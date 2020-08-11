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
    # @raise [UploadConcern::SubmitError]   If metadata was malformed.
    #
    # @return [Array<(Integer, Hash, Array<String>)>]
    #
    # @see onFileUploadSuccess() in app/assets/javascripts/feature/download.js
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

  module UploadEndpointDebug

    # Non-functional hints for RubyMine.
    # :nocov:
    include Shrine::UploadEndpointExt unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # =========================================================================
    # :section: Shrine::UploadEndpoint overrides
    # =========================================================================

    protected

    # handle_request
    #
    # @param [ActionDispatch::Request] request
    #
    # @return [Array<(Integer, Hash, Array<String>)>]
    #
    # This method overrides:
    # @see Shrine::UploadEndpoint#handle_request
    #
    def handle_request(request)
      super
        .tap do |result|
          __debug_ue(__method__, "RESULT -> #{result.inspect}") do
            { request: request }
          end
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
      super
        .tap do |result|
          __debug_ue(__method__, "RESULT -> #{result.inspect}") do
            { request: request }
          end
        end
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
      super
        .tap do |result|
          __debug_ue(__method__, "RESULT -> #{result.inspect}") do
            { request: request }
          end
        end
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
      super
        .tap do |result|
          __debug_ue(__method__, "RESULT -> #{result.inspect}") do
            { io: io, context: context, request: request }
          end
        end
    end

    # make_response
    #
    # @param [Shrine::UploadedFile, Hash] uploaded_file
    # @param [ActionDispatch::Request]    request
    #
    # @return [Array<(Integer, Hash, Array<String>)>]
    #
    # This method overrides:
    # @see Shrine::UploadEndpointExt#make_response
    #
    def make_response(uploaded_file, request)
      super
        .tap do |result|
          __debug_ue(__method__, "RESULT -> #{result.inspect}") do
            { uploaded_file: uploaded_file, request: request }
          end
        end
    end

    # =======================================================================
    # :section:
    # =======================================================================

    private

    module DebugMethods

      include Emma::Debug

      # Debug method for this class.
      #
      # @param [Array] args
      # @param [Hash]  opt
      # @param [Proc]  block            Passed to #__debug_items.
      #
      # @return [void]
      #
      def __debug_ue(*args, **opt, &block)
        meth = args.shift
        meth = meth.to_s.upcase if meth.is_a?(Symbol)
        opt[:leader] = ':::SHRINE::: UploadEndpoint'
        opt[:separator] ||= ' | '
        __debug_items(meth, *args, opt, &block)
      end

    end

    include DebugMethods
    extend  DebugMethods

  end if SHRINE_DEBUG

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Shrine::UploadEndpoint => Shrine::UploadEndpointExt
override Shrine::UploadEndpoint => Shrine::UploadEndpointDebug if SHRINE_DEBUG

__loading_end(__FILE__)
