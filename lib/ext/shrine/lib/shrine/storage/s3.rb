# lib/ext/shrine/lib/shrine/storage/s3.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions to the Shrine S3 storage.

__loading_begin(__FILE__)

require 'shrine/storage/s3'

class Shrine

  module Storage

    if DEBUG_SHRINE

      # Overrides adding extra debugging around method calls.
      #
      module S3Debug

        include Shrine::ExtensionDebugging

        # =====================================================================
        # :section: Shrine::Storage::S3 overrides
        # =====================================================================

        public

        # initialize
        #
        # @param [String]               bucket
        # @param [Aws::S3::Client, nil] client
        # @param [String, nil]          prefix
        # @param [Hash]                 upload_options
        # @param [Hash]                 multipart_threshold
        # @param [any]                  signer
        # @param [any]                  public
        # @param [Hash]                 s3_options
        #
        def initialize(
          bucket:,
          client:              nil,
          prefix:              nil,
          upload_options:      {},
          multipart_threshold: {},
          signer:              nil,
          public:              nil,
          **s3_options
        )
          __ext_debug do
            {
              bucket:              bucket,
              client:              client,
              prefix:              prefix,
              upload_options:      upload_options,
              multipart_threshold: multipart_threshold,
              signer:              signer,
              public:              public,
              s3_options:          s3_options
            }
          end
          super
        end

        # upload
        #
        # @param [IO, StringIO] io
        # @param [String]       id
        # @param [Hash]         shrine_metadata
        # @param [Hash]         upload_options
        #
        def upload(io, id, shrine_metadata: {}, **upload_options)
          __ext_debug do
            {
              io:              io,
              id:              id,
              shrine_metadata: shrine_metadata,
              upload_options:  upload_options,
            }
          end
          super
        end

        # open
        #
        # @param [String]  id
        # @param [Boolean] rewindable
        # @param [Hash]    options
        #
        def open(id, rewindable: true, **options)
          __ext_debug { { id: id, options: options } }
          super
        end

        # delete
        #
        # @param [String] id
        #
        def delete(id)
          __ext_debug { { id: id } }
          super
        end

        # =====================================================================
        # :section: Shrine::Storage::S3 overrides
        # =====================================================================

        protected

        # put
        #
        # @param [IO, StringIO] io
        # @param [String]       id
        # @param [Hash]         options
        #
        def put(io, id, **options)
          __ext_debug { { io: io, id: id, options: options } }
          super
        end

        # copy
        #
        # @param [IO, StringIO] io
        # @param [String]       id
        # @param [Hash]         options
        #
        def copy(io, id, **options)
          __ext_debug { { io: io, id: id, options: options } }
          super
        end

        # presign_put
        #
        # @param [String] id
        # @param [Hash]   options
        #
        # @return [Hash]
        #
        def presign_post(id, options)
          super
            .tap do |result|
              __ext_debug("--> #{result.inspect}") do
                { id: id, options: options }
              end
            end
        end

        # presign_put
        #
        # @param [String] id
        # @param [Hash]   options
        #
        # @return [Hash]
        #
        def presign_put(id, options)
          super
            .tap do |result|
              __ext_debug("--> #{result.inspect}") do
                { id: id, options: options }
              end
            end
        end

        # part_size
        #
        # @param [IO, StringIO] io
        #
        # @return [Integer]
        #
        def part_size(io)
          super
            .tap { |res| __ext_debug("--> #{res.inspect}") { { io: io } } }
        end

        # get_object
        #
        # @param [any]  object
        # @param [Hash] params
        #
        # @return [Array<(Array,Integer)>]
        #
        def get_object(object, params)
          super
            .tap do |result|
              __ext_debug("--> #{result.inspect}") do
                { object: object, params: params }
              end
            end
        end

        # copyable?
        #
        # @param [IO, StringIO] io
        #
        def copyable?(io)
          super
            .tap { |res| __ext_debug("--> #{res.inspect}") { { io: io } } }
        end

        # delete_objects
        #
        # @param [Array] objects
        #
        # @return [void]
        #
        def delete_objects(objects)
          __ext_debug("#{objects.size} objects")
          super
        end

      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Shrine::Storage::S3 => Shrine::Storage::S3Debug if DEBUG_SHRINE

__loading_end(__FILE__)
