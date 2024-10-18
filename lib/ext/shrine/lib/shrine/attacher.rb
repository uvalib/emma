# lib/ext/shrine/lib/shrine/attacher.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Shrine gem.

__loading_begin(__FILE__)

require 'shrine/attacher'

class Shrine

  if DEBUG_SHRINE

    # Overrides adding extra debugging around method calls.
    #
    #--
    # noinspection RubyTooManyMethodsInspection
    #++
    module AttacherDebug

      include Shrine::ExtensionDebugging

      # Non-functional hints for RubyMine type checking.
      # :nocov:
      unless ONLY_FOR_DOCUMENTATION
        include Shrine::Attacher::InstanceMethods
        include Shrine::Plugins::Activerecord::AttacherMethods
        include Shrine::Plugins::Entity::AttacherMethods
      end
      # :nocov:

      # =======================================================================
      # :section: Shrine::Attacher::InstanceMethods overrides
      # =======================================================================

      public

      # initialize
      #
      # @param [Shrine::UploadedFile] file
      # @param [Symbol]               cache
      # @param [Symbol]               store
      #
      def initialize(file: nil, cache: :cache, store: :store)
        __ext_debug { { file: file, cache: cache, store: store } }
        super
      end

      # assign
      #
      # @param [String, Hash, IO] value
      # @param [Hash]             options
      #
      # @return [Shrine::UploadedFile, nil]
      #
      def assign(value, **options)
        super
          .tap do |result|
            __ext_debug("--> #{result.inspect}") do
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
      def attach_cached(value, **options)
        super
          .tap do |result|
            __ext_debug("--> #{result.inspect}") do
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
      def attach(io, storage: store_key, **options)
        __ext_debug { { io: io, storage: storage, options: options } }
        super
      end

      # finalize
      #
      # @return [void]
      #
      def finalize
        __ext_debug
        super
      end

      # save
      #
      # @return [void]
      #
      def save
        __ext_debug
        super
      end

      # promote_cached
      #
      # @param [Hash] options           Passed to #promote.
      #
      # @return [Shrine::UploadedFile, nil]
      #
      def promote_cached(**options)
        __ext_debug { options }
        super
      end

      # promote
      #
      # @param [Symbol] storage
      # @param [Hash]   options
      #
      # @return [Shrine::UploadedFile, nil]
      #
      def promote(storage: store_key, **options)
        __ext_debug { { storage: storage, options: options } }
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
      def upload(io, storage = store_key, **options)
        __ext_debug { { io: io, storage: storage, options: options } }
        super
      end

      # destroy_previous
      #
      # @return [void]
      #
      def destroy_previous
        __ext_debug
        super
      end

      # destroy_attached
      #
      # @return [void]
      #
      def destroy_attached
        __ext_debug
        super
      end

      # destroy
      #
      # @return [void]
      #
      def destroy
        __ext_debug
        super
      end

      # change
      #
      # @param [Shrine::UploadedFile, nil] file
      #
      # @raise [ArgumentError]        If *file* is not an UploadedFile or *nil*
      #
      # @return [Shrine::UploadedFile, nil]
      #
      def change(file)
        __ext_debug { { file: file } }
        super
      end

      # Sets the attached file.
      #
      # @param [Shrine::UploadedFile, nil] file
      #
      # @raise [ArgumentError]        If *file* is not an UploadedFile or *nil*
      #
      # @return [Shrine::UploadedFile, nil]
      #
      def set(file)
        __ext_debug { { file: file } }
        super
      end

      # Returns the attached file.
      #
      # @return [Shrine::UploadedFile, nil]
      #
      def get
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
      end

      # load_data
      #
      # @param [Shrine::UploadedFile, Hash, String, nil] data
      #
      # @raise [ArgumentError]          If *value* is an invalid type.
      #
      # @return [UploadedFile, nil]
      #
      def load_data(data)
        __ext_debug { data.is_a?(Hash) ? data : { data: data } }
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
      def file=(file)
        __ext_debug { file.is_a?(Hash) ? file : { file: file } }
        super
      end

      # file!
      #
      # @raise [Shrine::Error]          If no file is attached.
      #
      # @return [Shrine::UploadedFile]
      #
      def file!
        super
          .tap { __ext_debug("--> #{_1.inspect}") }
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
      def uploaded_file(value)
        __ext_debug { value.is_a?(Hash) ? value : { value: value } }
        super
      end

      # =======================================================================
      # :section: Shrine::Plugins::Activerecord::AttacherMethods overrides
      # =======================================================================

      public

      # activerecord_validate
      #
      # @return [void]
      #
      def activerecord_validate
        __ext_debug
        super
      end

      # activerecord_before_save
      #
      # @return [void]
      #
      def activerecord_before_save
        __ext_debug
        super
      end

      # activerecord_after_save
      #
      # @return [void]
      #
      def activerecord_after_save
        __ext_debug
        super
      end

      # activerecord_after_destroy
      #
      # @return [void]
      #
      def activerecord_after_destroy
        __ext_debug
        super
      end

      # activerecord_persist
      #
      # @return [void]
      #
      def activerecord_persist
        __ext_debug
        super
      end

      # activerecord_reload
      #
      # @return [void]
      #
      def activerecord_reload
        __ext_debug
        super
      end

      # =======================================================================
      # :section: Shrine::Plugins::Entity::AttacherMethods overrides
      # =======================================================================

      public

      # load_entity
      #
      # @param [Model]          record
      # @param [Symbol, String] name
      #
      # @return [FileUploader]
      #
      def load_entity(record, name)
        __ext_debug { { name: name, record: record } }
        super
      end

      # set_entity
      #
      # @param [Model]          record
      # @param [Symbol, String] name
      #
      # @return [FileUploader]
      #
      def set_entity(record, name)
        super
          .tap do |result|
            __ext_debug("--> @context = #{result.inspect}") do
              { name: name, record: record }
            end
          end
      end

      # reload
      #
      # @return [FileUploader]
      #
      def reload
        __ext_debug
        # noinspection RubyMismatchedReturnType
        super
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Shrine::Attacher => Shrine::AttacherDebug if DEBUG_SHRINE

__loading_end(__FILE__)
