# app/models/concerns/file_uploader.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'shrine'

# FileUploader
#
# @!attribute [r] opts
#   Created via Shrine::ClassMethods#inherited.
#   @return [Hash]
#
# @!attribute [r] storages
#   Created via Shrine::ClassMethods#inherited.
#   @return [Hash]
#
# @!attribute [r] logger
#   Created via Shrine::ClassMethods#inherited.
#   @return [Logger]
#
# === Constants via Shrine::ClassMethods#inherited
#
# @!attribute [r] UploadedFile
#   Represents a file that was uploaded to a storage.
#   - Created via Shrine::ClassMethods#inherited.
#   - Augmented by all plugin FileMethods.
#   - Extended by all plugin FileClassMethods.
#   @return [Shrine::UploadedFile]
#
# @!attribute [r] Attachment
#   A convenience interface to the Shrine::Attacher object.  If :activerecord
#   plugin is loaded this module (1) syncs Shrine's validation errors with the
#   record, (2) triggers promoting after record is saved, (3) deletes the
#   uploaded file if attachment was replaced or the record destroyed.
#   - Created via Shrine::ClassMethods#inherited.
#   - Augmented by all plugin AttachmentMethods.
#   - Extended by all plugin AttachmentClassMethods.
#   @return [Shrine::Attachment]
#
# @!attribute [r] Attacher
#   Saves information about uploaded files as an attachment to a record (saving
#   the file data to a database column).  The attaching process requires a
#   temporary and a permanent storage to be registered (by default that's
#   :cache and :store).
#   - Created via Shrine::ClassMethods#inherited.
#   - Augmented by all plugin AttacherMethods.
#   - Extended by all plugin AttacherClassMethods.
#   @return [Shrine::Attacher]
#
# === Implementation Notes
# If #DEBUG_SHRINE is true then the overrides defined in Shrine::UploaderDebug
# (lib/ext/shrine/lib/shrine.rb) apply to the methods inherited from Shrine.
#
class FileUploader < Shrine

  # Any file smaller than this is considered bogus.
  #
  # @type [Integer]
  #
  MIN_SIZE = ENV_VAR['FILE_UPLOAD_MIN_SIZE'].to_i

  FORMATS = FileNaming.mime_to_fmt.keys.deep_freeze

  FORMAT_LIST =
    FileFormat::TYPES.map { |type|
      type.to_s.underscore.upcase.inspect
    }.join(', ').freeze

  ERROR = {
    mime_type: "type is not one of #{FORMAT_LIST}",
    extension: 'name should end with %s',
    min_size:  'too small to be a valid %s file'
  }.deep_freeze

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  Attacher.validate do
    # @see Shrine::Plugins::Validation::AttacherClassMethods#validate
    if FileNaming::STRICT_FORMATS
      fmt      = FileNaming.mime_to_fmt[file.mime_type]&.first
      exts     = fmt && FileNaming.file_extensions[fmt] || [file.extension]
      ext_list = exts.map { %Q(".#{_1}") }.join(', ')
      fmt      = fmt&.upcase || ''
      validate_mime_type(FORMATS, message: ERROR[:mime_type]) &&
      validate_extension(exts,    message: ERROR[:extension] % ext_list) &&
      validate_min_size(MIN_SIZE, message: ERROR[:min_size] % fmt)
    else
      validate_min_size(MIN_SIZE, message: (ERROR[:min_size] % nil).squish)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  if DEBUG_SHRINE

    include Shrine::ExtensionDebugging
    extend  Shrine::ExtensionDebugging

    # =========================================================================
    # :section: Shrine::ClassMethods overrides
    # =========================================================================

    public

    # upload
    #
    # @param [IO, StringIO] io
    # @param [Symbol]       storage
    # @param [Hash]         options
    #
    # @return [Shrine::UploadedFile]
    #
    def self.upload(io, storage, **options)
      __ext_debug { { io: io, storage: storage, options: options } }
      # noinspection RubyMismatchedReturnType
      super
    end

    # uploaded_file
    #
    # @param [Shrine::UploadedFile, Hash, String, nil] object
    #
    # @raise [ArgumentError]          If *object* is an invalid type.
    #
    # @return [Shrine::UploadedFile]
    #
    def self.uploaded_file(object)
      __ext_debug { { object: object } }
      # noinspection RubyMismatchedReturnType
      super
    end

    # with_file
    #
    # @param [IO, StringIO] io
    #
    # @return [void]
    #
    def self.with_file(io)
      __ext_debug { { io: io } }
      start = timestamp
      super
        .tap { __ext_debug(start) }
    end

    # =========================================================================
    # :section: Shrine::InstanceMethods overrides
    # =========================================================================

    public

    # initialize
    #
    # @param [Symbol] storage_key
    #
    def initialize(storage_key)
      __ext_debug { { storage_key: storage_key } }
      super
    end

    # upload
    #
    # @param [IO, StringIO] io
    # @param [Hash]         options
    #
    # @return [Shrine::UploadedFile]
    #
    def upload(io, **options)
      __ext_debug { { io: io, options: options } }
      start = timestamp
      # noinspection RubyMismatchedReturnType
      super
        .tap { __ext_debug(start) }
    end

    # generate_location
    #
    # @param [IO, StringIO] io
    # @param [Hash]         metadata
    # @param [Hash]         options
    #
    # @return [String]
    #
    def generate_location(io, metadata: {}, **options)
      __ext_debug { { io: io, metadata: metadata, options: options } }
      start = timestamp
      super
        .tap { __ext_debug(start) }
    end

    # extract_metadata
    #
    # @param [IO, StringIO] io
    # @param [Hash]         options
    #
    # @return [Hash{String=>String,Integer}]
    #
    def extract_metadata(io, **options)
      __ext_debug { { io: io, options: options } }
      start = timestamp
      super
        .tap { __ext_debug(start) }
    end

  end

end

__loading_end(__FILE__)
