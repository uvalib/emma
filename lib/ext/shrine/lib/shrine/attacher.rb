# lib/ext/shrine/lib/shrine/attacher.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Shrine gem.

__loading_begin(__FILE__)

require 'shrine/attacher'

class Shrine

  #--
  # noinspection RubyTooManyMethodsInspection
  #++
  module AttacherDebug

    # Non-functional hints for RubyMine.
    # :nocov:
    unless ONLY_FOR_DOCUMENTATION
      include Shrine::Attacher::InstanceMethods
      include Shrine::Plugins::Activerecord::AttacherMethods
      include Shrine::Plugins::Entity::AttacherMethods
    end
    # :nocov:

    # =========================================================================
    # :section: Shrine::Attacher::InstanceMethods overrides
    # =========================================================================

    public

    # initialize
    #
    # @param [Shrine::UploadedFile] file
    # @param [Symbol]               cache
    # @param [Symbol]               store
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#initialize
    #
    def initialize(file: nil, cache: :cache, store: :store)
      __debug_attacher('NEW') { { file: file, cache: cache, store: store } }
      super
    end

    # assign
    #
    # @param [String, Hash, IO] value
    # @param [Hash]             options
    #
    # @return [Shrine::UploadedFile, nil]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#assign
    #
    def assign(value, **options)
      super
        .tap do |result|
          __debug_attacher(__method__, "RESULT -> #{result.inspect}") do
            { value: value, options: options }
          end
        end
    end

    # attach_cached
    #
    # @param [String, Hash, IO] value
    # @param [Hash]             options   To #attach if *value* is an IO.
    #
    # @raise [Shrine::Error]    If the file is not in :cache storage.
    #
    # @return [Shrine::UploadedFile]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#attach_cached
    #
    def attach_cached(value, **options)
      # noinspection RubyYardReturnMatch
      super
        .tap do |result|
          __debug_attacher(__method__, "RESULT -> #{result.inspect}") do
            { value: value, options: options }
          end
        end
    end

    # attach
    #
    # @param [IO, StringIO] io
    # @param [Symbol]       storage
    # @param [Hash]         options   Passed to #upload.
    #
    # @return [Shrine::UploadedFile, nil]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#attach
    #
    def attach(io, storage: store_key, **options)
      __debug_attacher(__method__) do
        { io: io, storage: storage, options: options }
      end
      super
    end

    # finalize
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#finalize
    #
    def finalize
      __debug_attacher(__method__)
      super
    end

    # save
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#save
    #
    def save
      __debug_attacher(__method__)
      super
    end

    # promote_cached
    #
    # @param [Hash] options           Passed to #promote.
    #
    # @return [Shrine::UploadedFile, nil]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#promote_cached
    #
    def promote_cached(**options)
      __debug_attacher(__method__) { options }
      # noinspection RubyYardReturnMatch
      super
    end

    # promote
    #
    # @param [Symbol] storage
    # @param [Hash]   options
    #
    # @return [Shrine::UploadedFile, nil]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#promote
    #
    def promote(storage: store_key, **options)
      __debug_attacher(__method__) { { storage: storage, options: options } }
      # noinspection RubyYardReturnMatch
      super
    end

    # upload
    #
    # @param [IO, StringIO] io
    # @param [Symbol]       storage
    # @param [Hash]         options
    #
    # @return [Shrine::UploadedFile]
    #
    # @see Shrine::InstanceMethods#upload
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#attach
    #
    def upload(io, storage = store_key, **options)
      __debug_attacher(__method__) do
        { io: io, storage: storage, options: options }
      end
      super
    end

    # destroy_previous
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#destroy_previous
    #
    def destroy_previous
      __debug_attacher(__method__)
      super
    end

    # destroy_attached
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#destroy_attached
    #
    def destroy_attached
      __debug_attacher(__method__)
      super
    end

    # destroy
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#destroy
    #
    def destroy
      __debug_attacher(__method__)
      super
    end

    # change
    #
    # @param [Shrine::UploadedFile, nil] file
    #
    # @raise [ArgumentError]          If *file* is not an UploadedFile or *nil*
    #
    # @return [Shrine::UploadedFile, nil]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#change
    #
    def change(file)
      __debug_attacher(__method__) { { file: file } }
      super
    end

    # Sets the attached file.
    #
    # @param [Shrine::UploadedFile, nil] file
    #
    # @raise [ArgumentError]          If *file* is not an UploadedFile or *nil*
    #
    # @return [Shrine::UploadedFile, nil]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#set
    #
    def set(file)
      __debug_attacher(__method__) { { file: file } }
      super
    end

    # Returns the attached file.
    #
    # @return [Shrine::UploadedFile, nil]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#get
    #
    def get
      super
        .tap { |res| __debug_attacher(__method__, "RESULT -> #{res.inspect}") }
    end

    # load_data
    #
    # @param [Shrine::UploadedFile, Hash, String, nil] data
    #
    # @raise [ArgumentError]          If *value* is an invalid type.
    #
    # @return [UploadedFile, nil]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#load_data
    #
    def load_data(data)
      __debug_attacher(__method__) { data.is_a?(Hash) ? data : { data: data } }
      # noinspection RubyYardReturnMatch
      super
    end

    # Sets the attached file.
    #
    # @param [Shrine::UploadedFile, nil] file
    #
    # @raise [ArgumentError]          If *file* is an invalid type.
    #
    # @return [Shrine::UploadedFile, nil]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#file=
    #
    def file=(file)
      __debug_attacher(__method__) { file.is_a?(Hash) ? file : { file: file } }
      super
    end

    # file!
    #
    # @raise [Shrine::Error]          If no file is attached.
    #
    # @return [Shrine::UploadedFile]
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#file!
    #
    def file!
      super
        .tap { |res| __debug_attacher(__method__, "RESULT -> #{res.inspect}") }
    end

    # uploaded_file
    #
    # @param [Shrine::UploadedFile, Hash, String] value
    #
    # @raise [ArgumentError]          If *value* is an invalid type.
    #
    # @return [Shrine::UploadedFile]
    #
    # @see Shrine::ClassMethods#uploaded_file
    #
    # This method overrides:
    # @see Shrine::Attacher::InstanceMethods#uploaded_file
    #
    def uploaded_file(value)
      __debug_attacher(__method__) do
        value.is_a?(Hash) ? value : { value: value }
      end
      super
    end

    # =========================================================================
    # :section: Shrine::Plugins::Activerecord::AttacherMethods overrides
    # =========================================================================

    public

    # activerecord_validate
    #
    # @return [void]
    #
    # This method overrides:
    # @see Shrine::Plugins::Activerecord::AttacherMethods#activerecord_validate
    #
    def activerecord_validate
      __debug_attacher(__method__)
      super
    end

    # activerecord_before_save
    #
    # @return [void]
    #
    # This method overrides:
    # @see Shrine::Plugins::Activerecord::AttacherMethods#activerecord_before_save
    #
    def activerecord_before_save
      __debug_attacher(__method__)
      super
    end

    # activerecord_after_save
    #
    # @return [void]
    #
    # This method overrides:
    # @see Shrine::Plugins::Activerecord::AttacherMethods#activerecord_after_save
    #
    def activerecord_after_save
      __debug_attacher(__method__)
      super
    end

    # activerecord_after_destroy
    #
    # @return [void]
    #
    # This method overrides:
    # @see Shrine::Plugins::Activerecord::AttacherMethods#activerecord_after_destroy
    #
    def activerecord_after_destroy
      __debug_attacher(__method__)
      super
    end

    # activerecord_persist
    #
    # @return [void]
    #
    # This method overrides:
    # @see Shrine::Plugins::Activerecord::AttacherMethods#activerecord_persist
    #
    def activerecord_persist
      __debug_attacher(__method__)
      super
    end

    # activerecord_reload
    #
    # @return [void]
    #
    # This method overrides:
    # @see Shrine::Plugins::Activerecord::AttacherMethods#activerecord_reload
    #
    def activerecord_reload
      __debug_attacher(__method__)
      super
    end

    # =========================================================================
    # :section: Shrine::Plugins::Entity::AttacherMethods overrides
    # =========================================================================

    public

    # load_entity
    #
    # @param [Upload]         record
    # @param [Symbol, String] name
    #
    # @return [FileUploader]
    #
    # This method overrides:
    # @see Shrine::Plugins::Entity::AttacherMethods#load_entity
    #
    def load_entity(record, name)
      __debug_attacher(__method__) { { name: name, record: record } }
      super
    end

    # set_entity
    #
    # @param [Upload]         record
    # @param [Symbol, String] name
    #
    # @return [FileUploader]
    #
    # This method overrides:
    # @see Shrine::Plugins::Entity::AttacherMethods#set_entity
    #
    def set_entity(record, name)
      super
        .tap do |res|
          __debug_attacher(__method__, "RESULT @context = #{res.inspect}") do
            { name: name, record: record }
          end
        end
    end

    # reload
    #
    # @return [FileUploader]
    #
    # This method overrides:
    # @see Shrine::Plugins::Entity::AttacherMethods#reload
    #
    def reload
      __debug_attacher(__method__)
      # noinspection RubyYardReturnMatch
      super
    end

    # =========================================================================
    # :section:
    # =========================================================================

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
      def __debug_attacher(*args, **opt, &block)
        meth = args.shift
        meth = meth.to_s.upcase if meth.is_a?(Symbol)
        opt[:leader] = ':::SHRINE::: Attacher'
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

override Shrine::Attacher => Shrine::AttacherDebug if SHRINE_DEBUG

__loading_end(__FILE__)
