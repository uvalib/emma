# app/helpers/encoding_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Character encoding support methods.
#
module EncodingHelper

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Convert a string to UTF-8.
  #
  # If *xhr* is *true*, the result is encoded for use in HTTP message headers
  # passed back to the client as flash messages.
  #
  # @param [ActiveSupport::SafeBuffer, String, nil] value
  # @param [Boolean, nil]                           xhr
  #
  # @return [ActiveSupport::SafeBuffer]   If *value* was HTML-safe.
  # @return [String]                      Otherwise.
  #
  # @see #to_utf8
  # @see #xhr_encode
  #
  def to_utf(value, xhr: nil, **)
    xhr ? xhr_encode(value) : to_utf8(value.to_s)
  end

  # Encode a string for use in HTTP message headers passed back to the client
  # as flash messages.
  #
  # @param [any, nil] value           ActiveSupport::SafeBuffer, String
  #
  # @return [ActiveSupport::SafeBuffer, String]
  #
  # @see file:app/assets/javascripts/shared/flash.js *xhrDecode()*
  #
  # === Implementation Notes
  # JavaScript uses UTF-16 strings, so the most straightforward way to prepare
  # a string to be passed back to the client would be to encode as 'UTF-16BE',
  # however that would halve the number of characters that could be transmitted
  # via 'X-Flash-Message'.
  #
  # Another strategy would be to use ERB::Util#url_encode to produce only
  # ASCII-equivalent characters, then use "decodeURIComponent()" on the client
  # side to restore the string.  However, that method encodes *many* characters
  # that don't need to be encoded for this purpose (e.g. ' ' becomes '%20').
  #
  # This method takes a similar approach, but only encodes non-ASCII-equivalent
  # characters. Assuming that these will be infrequent for flash messages, this
  # should minimize the impact of encoding on the size of the transmitted
  # string.  (The '%' character is also encoded to avoid ambiguity.)
  #
  def xhr_encode(value)
    str = value.to_s
    return to_utf8(str) if str.match?(/%[0-9A-F][0-9A-F]/i)
    str = str.dup       if str.frozen? || (str.object_id == value.object_id)
    str.force_encoding('US-ASCII').bytes.map { |b|
      case b
        when 128.. then sprintf('%%%02X', b)  # Encode beyond US-ASCII range.
        when 37    then '%25'                 # Encode '%' to avoid ambiguity.
        else            b.chr                 # General US-ASCII character.
      end
    }.join.force_encoding('UTF-8')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
