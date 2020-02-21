# app/models/concerns/ocf_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An OCF-based file object.
#
# @see DaisyFormat
# @see EpubFormat
# @see FileFormat
#
module OcfFormat

  include FileFormat

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configured properties for this file format.
  #
  # @type [Hash{Symbol=>String,Array,Hash}]
  #
  OCF_FORMAT = format_configuration('emma.ocf').deep_freeze

  # MIME type(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = OCF_FORMAT[:mimes]

  # File extension(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = OCF_FORMAT[:exts]

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = OCF_FORMAT[:fields]

  # A mapping of format field to the equivalent Search::Record::MetadataRecord
  # field.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  FIELD_MAP = OCF_FORMAT[:map]

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # configuration
  #
  # @return [Hash{Symbol=>String,Array,Hash}]
  #
  # This method overrides:
  # @see FileFormat#configuration
  #
  def configuration
    OCF_FORMAT
  end

end

__loading_end(__FILE__)
