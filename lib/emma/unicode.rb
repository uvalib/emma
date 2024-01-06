# lib/emma/unicode.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Unicode utilities.
#
#--
# noinspection RubyQuotedStringsInspection
#++
module Emma::Unicode

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A matcher for one or more symbol-like characters.
  #
  # @type [Regexp]
  #
  SYMBOLS = %w[
    \u2000-\u{FFFF}
    \u{1F000}-\u{1FFFF}
  ].join.then { |char_ranges| Regexp.new("[#{char_ranges}]+") }.freeze

  # Indicate whether the string contains only characters that fall outside the
  # normal text range.  Always `false` if *text* is not a string.
  #
  # @param [String, *] text
  #
  def only_symbols?(text)
    text.is_a?(String) && text.present? && text.remove(SYMBOLS).blank?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a single character.
  #
  # @param [String, Integer] v
  #
  # @return [String]
  #
  def char(v)
    v.is_a?(Integer) ? v.chr(Encoding::UTF_8) : v.chr
  end

  # Pad a character with thin spaces.
  #
  # @param [String, Integer]      v
  # @param [String, Integer, nil] pad     Default: #THIN_SPACE
  # @param [String, Integer, nil] left    Default: *pad*
  # @param [String, Integer, nil] right   Default: *l_pad*
  #
  # @return [String]
  #
  # @note Currently unused.
  #
  def pad_char(v, pad: nil, left: nil, right: nil)
    left  ||= pad || THIN_SPACE
    right ||= pad || left
    [left, v, right].map { |c| char(c) }.join
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  EN_SPACE          = "\u2002"    #   EN SPACE
  THIN_SPACE        = "\u2009"    #   THIN SPACE
  EN_DASH           = "\u2013"    # – EN DASH
  EM_DASH           = "\u2014"    # — EM DASH
  UP_TRIANGLE       = "\u25B2"    # ▲ BLACK UP-POINTING TRIANGLE
  DELTA             = "\u25B3"    # △ WHITE UP-POINTING TRIANGLE
  DOWN_TRIANGLE     = "\u25BC"    # ▼ BLACK DOWN-POINTING TRIANGLE
  REVERSE_DELTA     = "\u25BD"    # ▽ WHITE DOWN-POINTING TRIANGLE
  BLACK_CIRCLE      = "\u25CF"    # ● BLACK CIRCLE
  BLACK_STAR        = "\u2605"    # ★ BLACK STAR
  WARNING_SIGN      = "\u26A0"    # ⚠ WARNING SIGN
  CHECK             = "\u2714"    # ✔ HEAVY CHECK MARK
  HEAVY_X           = "\u2716"    # ✖ HEAVY MULTIPLICATION X
  ASTERISK          = "\u2731"    # ✱ HEAVY ASTERISK
  QUESTION          = "\u2754"    # ❔ WHITE QUESTION MARK ORNAMENT
  BANG              = "\u2755"    # ❕  WHITE EXCLAMATION MARK ORNAMENT
  HEAVY_PLUS        = "\u2795"    # ➕ HEAVY PLUS SIGN
  HEAVY_MINUS       = "\u2796"    # ➖ HEAVY MINUS SIGN
  RIGHT_ARROWHEAD   = "\u27A4"    # ➤ BLACK RIGHT ARROWHEAD
  OPEN_FILE_FOLDER  = "\u{1F4C2}" # 📂 OPEN FILE FOLDER
  SCROLL            = "\u{1F4DC}" # 📜 SCROLL
  MAGNIFIER         = "\u{1F50D}" # 🔍 LEFT-POINTING MAGNIFYING GLASS
  PENCIL            = "\u{1F589}" # 🖉 LOWER LEFT PENCIL
  DELIVERY_TRUCK    = "\u{1F69A}" # 🚚 DELIVERY TRUCK

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
