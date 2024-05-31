# lib/emma/mime.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'marcel'
require 'marcel/mime_type'

# Generic MIME type methods.
#
# @see file:config/initializers/mime_types.rb
#
module Emma::Mime

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
    # noinspection RubyMismatchedArgumentType
    result = Marcel::MimeType.for(extension: ext)
    result unless result == Marcel::MimeType::BINARY
  end

end

__loading_end(__FILE__)
