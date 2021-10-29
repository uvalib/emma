# app/records/concerns/api/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'

# Methods mixed in to record elements related to catalog titles.
#
module Api::Shared::TitleMethods

  include Api::Shared::CommonMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Model
    # :nocov:
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    full_title
  end

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # A unique identifier for this catalog title.
  #
  # @return [String]
  #
  def identifier
    not_implemented 'to be overridden'
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sanitizer for catalog title contents.
  #
  # @type [Sanitize]
  #
  CONTENT_SANITIZE = Sanitize.new(elements: %w(br b i em strong))

  # The full title in a form that it can be used for comparisons.
  #
  # @return [String]
  #
  def normalized_title
    normalized(full_title)
  end

  # The title and subtitle of this catalog title.
  #
  # @return [String]
  #
  def full_title
    ti = get_value(*title_fields)
    st = get_value(*subtitle_fields)
    if ti && st
      # Remove the automatically-appended subtitle (in the case of search
      # results entries).
      ti = ti.delete_suffix(st).rstrip.delete_suffix(':') if ti.end_with?(st)
      # Append the subtitle only if it doesn't appear to already be included in
      # the base title itself.
      ti = "#{ti}: #{st}" unless significant(ti).include?(significant(st))
    end
    ti || st || '???'
  end

  # The year of publication.
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  # @see Search::Shared::TitleMethods#date_fields
  #
  def year
    date_fields.map { |date|
      (year = IsoYear.cast(try(date))) and positive(year.to_s)
    }.compact.sort.first
  end

  # The synopsis or description with rudimentary formatting.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If the value cannot be determined.
  #
  # == Implementation Notes
  # [1]  Repair malformed HTML entities.
  # [2]  Transform one or more newlines into a pair of breaks.
  # [3]  Normalize space characters.
  # [4]  Strip leading/trailing spaces only after normalization.
  # [5]  Eliminate sequences like "<p><p>".
  # [6]  Normalize breaks, removing any leading spaces.
  # [7]  Eliminate orphaned elements like "<p><br/>".
  # [8]  Put explicit list elements on their own lines.
  # [9]  Put implied list elements on their own lines.
  # [10] Put *apparent* list elements on their own lines.
  # [11] Treat a run of spaces as an implied paragraph break.
  # [12] Special paragraph break.
  # [13] Reduce runs of breaks to just a pair of breaks.
  # [14] Remove leading breaks.
  # [15] Remove trailing breaks.
  #
  def contents
    return unless (text = get_value(*contents_fields)).present?
    # noinspection RubyNilAnalysis
    text.gsub!(/(?<![&])(#\d{1,5};)/,    '&\1')             # [1]
    text.gsub!(/([[:space:]]*\n)+/,      '<br/><br/>')      # [2]
    text.gsub!(/[[:space:]]/,            ' ')               # [3]
    text.strip!                                             # [4]
    text.gsub!(/<([^>])>(<\1>)+/,        '')                # [5]
    text.gsub!(/\s*<br\s*\/?>/,          '<br/>')           # [6]
    text.gsub!(/<[^>]><br.>/,            '<br/>')           # [7]
    text.gsub!(/([•∙·]+)\s*/,            '<br/>•&nbsp;')    # [8]
    text.gsub!(/<br.>\s{2,}/,            '<br/>•&nbsp;')    # [9]
    text.gsub!(/\s+(\d+\.|[*?+])\s+/,    '<br/>\1&nbsp;')   # [10]
    text.gsub!(/\s+(--|—)\s*([A-Z0-9])/, '<br/>\1&nbsp;\2') # [10]
    text.gsub!(/\s{3,}/,                 '<br/><br/>')      # [11]
    text.gsub!(/(<P>)+/,                 '<br/><br/>')      # [12]
    text.gsub!(/(<br.>){3,}/,            '<br/><br/>')      # [13]
    text.sub!( /\A(<br.>)+/,             '')                # [14]
    text.sub!( /(<br.>)+\z/,             '')                # [15]
    CONTENT_SANITIZE.fragment(text).html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Reduce a string for comparison with another by eliminating characters to
  # ignore for comparison.
  #
  # @param [String] value
  #
  # @return [String]
  #
  def significant(value)
    normalized(value).remove!(' ')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A link to a title's thumbnail image.
  #
  # @return [String]
  # @return [nil]                     If the link was not present.
  #
  def thumbnail_image
  end

  # A link to a title's cover image if present.
  #
  # @return [String]
  # @return [nil]                     If the link was not present.
  #
  def cover_image
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Field(s) that may hold the title string.
  #
  # @return [Array<Symbol>]
  #
  def title_fields
    []
  end

  # Field(s) that may hold the subtitle string.
  #
  # @return [Array<Symbol>]
  #
  def subtitle_fields
    []
  end

  # Field(s) that may hold date information about the title.
  #
  # @return [Array<Symbol>]
  #
  def date_fields
    []
  end

  # Field(s) that may hold content information about the title.
  #
  # @return [Array<Symbol>]
  #
  def contents_fields
    []
  end

end

__loading_end(__FILE__)
