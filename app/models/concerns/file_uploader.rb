# app/models/concerns/file_uploader.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'shrine'

# FileUploader
#
class FileUploader < Shrine

  include FileNaming

  # Any file smaller than this is considered bogus.
  #
  # @type [Integer]
  #
  MIN_SIZE = 100 # bytes

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
    $stderr.puts '*** START >>> Attacher.validate'
    fmt      = FileNaming.mime_to_fmt[file.mime_type]&.first
    exts     = fmt && FileNaming.file_extensions[fmt] || [file.extension]
    ext_list = exts.map { |e| %Q(".#{e}") }.join(', ')
    fmt      = fmt&.upcase || ''
    validate_mime_type(FORMATS, message: ERROR[:mime_type]) &&
    validate_extension(exts,    message: ERROR[:extension] % ext_list) &&
    validate_min_size(MIN_SIZE, message: ERROR[:min_size] % fmt)
    $stderr.puts "*** END   <<< Attacher.validate - errors = #{errors.inspect}"
  end

end

__loading_end(__FILE__)
