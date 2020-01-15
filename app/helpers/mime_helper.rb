# app/helpers/mime_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'marcel'
require 'marcel/mime_type'

# Generic MIME type methods.
#
# @see config/initializers/mime_types.rb
#
module MimeHelper

  def self.included(base)
    __included(base, '[MimeHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
  DEFAULT_MIME_TYPE = 'application/octet-stream'

  # A mapping of MIME type to file extension.
  #
  # @type [Hash{String=>Array<String>}]
  #
  MIME_TO_EXT = {
    'application/octet-stream':     %w(zip rar),
    'application/x-brf':            'brf',        # NOTE: fake MIME type
    'application/x-daisy':          'daisy',      # NOTE: fake MIME type
    'application/x-rar-compressed': 'rar',
    'application/x-zip-compressed': 'zip',
    'application/xml-dtd':          'dtd',
    'application/zip':              'zip',
    'multipart/x-zip':              'zip',
    'text/xml':                     'xsd',
  }.map { |k, v| [k.to_s, Array.wrap(v)] }.deep_freeze

  # A mapping of file extension to MIME type.
  #
  # @type [Hash{String=>String}]
  #
  EXT_TO_MIME = {
    brf:   'application/x-brf',                   # NOTE: fake MIME type
    daisy: 'application/x-daisy',                 # NOTE: fake MIME type
    dtd:   'application/xml-dtd',
    rar:   'application/x-rar-compressed',
    xsd:   'text/xml',
    zip:   'application/zip',
  }.stringify_keys.deep_freeze
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given string matches a known file extension.
  #
  # @param [String, Symbol] ext
  #
  def known_extension?(ext)
    ext_to_mime(ext).present?
  end

  # Given a file extension, return the associated MIME type.
  #
  # @param [String, Symbol] ext
  #
  # @return [String]
  # @return [nil]
  #
  def ext_to_mime(ext)
=begin
    Mime[ext.to_s.downcase]&.to_s
=end
    result = Marcel::MimeType.for(extension: ext)
    result = nil if result == Marcel::MimeType::BINARY
    __debug { "MIME ext #{ext.inspect} -> #{result.inspect}" }
    result
  end

=begin
  # Given a file extension, return the associated MIME type.
  #
  # @param [String] mime
  #
  # @return [String]
  # @return [nil]
  #
  def mime_to_ext(mime)
    MIME_TO_EXT[mime] if mime &&= normalize_mime(mime)
  end

  # Given a file extension, return the associated MIME type.
  #
  # @param [String, Symbol] ext
  #
  # @return [String]
  # @return [nil]
  #
  def ext_to_mime(ext)
    EXT_TO_MIME[ext] if ext &&= ext.to_s.downcase
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
  # normalize_mime
  #
  # @param [String] mime
  #
  # @return [String]
  #
  def normalize_mime(mime)
    mime = mime.to_s.strip.presence
    mime = "application/#{mime}" if mime && !mime.include?('/')
    mime || DEFAULT_MIME_TYPE
  end
=end

end

__loading_end(__FILE__)
