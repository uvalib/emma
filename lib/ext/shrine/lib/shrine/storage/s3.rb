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

    module S3Debug

      # =======================================================================
      # :section: Shrine::Storage::S3 overrides
      # =======================================================================

      public

      # initialize
      #
      # @param [*]    bucket
      # @param [*]    client
      # @param [*]    prefix
      # @param [Hash] upload_options
      # @param [Hash] multipart_threshold
      # @param [*]    signer
      # @param [*]    public
      # @param [Hash] s3_options
      #
      # This method overrides:
      # @see Shrine::Storage::S3#initialize
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
        __debug_s3('NEW') do
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
      # This method overrides:
      # @see Shrine::Storage::S3#upload
      #
      def upload(io, id, shrine_metadata: {}, **upload_options)
        __debug_s3(__method__) do
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
      # This method overrides:
      # @see Shrine::Storage::S3#open
      #
      def open(id, rewindable: true, **options)
        __debug_s3(__method__) { { id: id, options: options } }
        super
      end

      # delete
      #
      # @param [String] id
      #
      # This method overrides:
      # @see Shrine::Storage::S3#delete
      #
      def delete(id)
        __debug_s3(__method__) { { id: id } }
        super
      end

      # =======================================================================
      # :section: Shrine::Storage::S3 overrides
      # =======================================================================

      protected

      # put
      #
      # @param [IO, StringIO] io
      # @param [String]       id
      # @param [Hash]         options
      #
      # This method overrides:
      # @see Shrine::Storage::S3#put
      #
      def put(io, id, **options)
        __debug_s3(__method__) { { io: io, id: id, options: options } }
        super
      end

      # copy
      #
      # @param [IO, StringIO] io
      # @param [String]       id
      # @param [Hash]         options
      #
      # This method overrides:
      # @see Shrine::Storage::S3#copy
      #
      def copy(io, id, **options)
        __debug_s3(__method__) { { io: io, id: id, options: options } }
        super
      end

      # presign_put
      #
      # @param [String] id
      # @param [Hash]   options
      #
      # @return [Hash]
      #
      # This method overrides:
      # @see Shrine::Storage::S3#presign_put
      #
      def presign_post(id, options)
        super
          .tap do |result|
            __debug_s3(__method__, "RESULT -> #{result.inspect}") do
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
      # This method overrides:
      # @see Shrine::Storage::S3#presign_put
      #
      def presign_put(id, options)
        super
          .tap do |result|
            __debug_s3(__method__, "RESULT -> #{result.inspect}") do
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
      # This method overrides:
      # @see Shrine::Storage::S3#part_size
      #
      def part_size(io)
        super
          .tap do |result|
            __debug_s3(__method__, "RESULT -> #{result.inspect}") do
              { io: io }
            end
          end
      end

      # get_object
      #
      # @param [*]    object
      # @param [Hash] params
      #
      # @return [Array<(Array,Integer)>]
      #
      # This method overrides:
      # @see Shrine::Storage::S3#get_object
      #
      def get_object(object, params)
        super
          .tap do |result|
            __debug_s3(__method__, "RESULT -> #{result.inspect}") do
              { object: object, params: params }
            end
          end
      end

      # copyable?
      #
      # @param [IO, StringIO] io
      #
      # This method overrides:
      # @see Shrine::Storage::S3#copyable?
      #
      def copyable?(io)
        super
          .tap do |result|
            __debug_s3(__method__, "RESULT -> #{result.inspect}") do
              { io: io }
            end
          end
      end

      # delete_objects
      #
      # @param [Array] objects
      #
      # @return [void]
      #
      # This method overrides:
      # @see Shrine::Storage::S3#delete_objects
      #
      def delete_objects(objects)
        __debug_s3(__method__, "#{objects.size} objects")
        super
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
        def __debug_s3(*args, **opt, &block)
          meth = args.shift
          meth = meth.to_s.upcase if meth.is_a?(Symbol)
          opt[:leader] = ':::SHRINE::: Storage::S3'
          opt[:separator] ||= ' | '
          __debug_items(meth, *args, opt, &block)
        end

      end

      include DebugMethods
      extend  DebugMethods

    end if SHRINE_DEBUG

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Shrine::Storage::S3 => Shrine::Storage::S3Debug if SHRINE_DEBUG

__loading_end(__FILE__)
