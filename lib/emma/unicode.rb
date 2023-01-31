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
  EM_SPACE          = "\u2003"    #   EM SPACE
  THIN_SPACE        = "\u2009"    #   THIN SPACE
  EN_DASH           = "\u2013"    # – EN DASH
  EM_DASH           = "\u2014"    # — EM DASH
  UP_TRIANGLE       = "\u25B2"    # ▲ BLACK UP-POINTING TRIANGLE
  DELTA             = "\u25B3"    # △ WHITE UP-POINTING TRIANGLE
  RIGHT_TRIANGLE    = "\u25B6"    # ▶ BLACK RIGHT-POINTING TRIANGLE
  DOWN_TRIANGLE     = "\u25BC"    # ▼ BLACK DOWN-POINTING TRIANGLE
  REVERSE_DELTA     = "\u25BD"    # ▽ WHITE DOWN-POINTING TRIANGLE
  LEFT_TRIANGLE     = "\u25C0"    # ◀ BLACK LEFT-POINTING TRIANGLE
  BLACK_CIRCLE      = "\u25CF"    # ● BLACK CIRCLE
  BLACK_STAR        = "\u2605"    # ★ BLACK STAR
  WARNING_SIGN      = "\u26A0"    # ⚠ WARNING SIGN
  CHECK_MARK        = "\u2714"    # ✔ HEAVY CHECK MARK
  HEAVY_X           = "\u2716"    # ✖ HEAVY MULTIPLICATION X
  ASTERISK          = "\u2731"    # ✱ HEAVY ASTERISK
  QUESTION          = "\u2754"    # ❔ WHITE QUESTION MARK ORNAMENT
  BANG              = "\u2755"    # ❕  WHITE EXCLAMATION MARK ORNAMENT
  HEAVY_PLUS        = "\u2795"    # ➕ HEAVY PLUS SIGN
  HEAVY_MINUS       = "\u2796"    # ➖ HEAVY MINUS SIGN
  RIGHT_ARROWHEAD   = "\u27A4"    # ➤ BLACK RIGHT ARROWHEAD
  OPEN_FILE_FOLDER  = "\u{1F4C2}" # 📂 OPEN FILE FOLDER
  SCROLL            = "\u{1F4DC}" # 📜 SCROLL
  MEMO              = "\u{1F4DD}" # 📝 MEMO
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
