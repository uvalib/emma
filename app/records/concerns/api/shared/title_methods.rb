# app/records/concerns/api/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'

# Methods mixed in to record elements related to catalog titles.
#
module Api::Shared::TitleMethods

  include Emma::Common

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

  # A unique identifier for this catalog title.
  #
  # @return [String]
  #
  def identifier
    raise 'To be overridden'
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The author(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def author_list(**opt)
    creator_list(**opt)
  end

  # The editor(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def editor_list(**)
    []
  end

  # The composer(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def composer_list(**)
    []
  end

  # The lyricist(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def lyricist_list(**)
    []
  end

  # The arranger(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def arranger_list(**)
    []
  end

  # The translator(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def translator_list(**)
    []
  end

  # The creator(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def creators(**opt)
    creator_list(**opt)
  end

  # The author(s)/creator(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #contributor_list.
  #
  # @return [Array<String>]
  #
  def creator_list(**opt)
    contributor_list(**opt)
  end

  # All contributor(s) to this catalog title.
  #
  # @return [Array<String>]
  #
  def contributor_list(**)
    []
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

  # The ISBN.
  #
  # @return [String]
  # @return [nil]                     If the value cannot be determined.
  #
  def isbn
  end

  # Related ISBNs omitting the main ISBN if part of the data array.
  #
  # @return [Array<String>]
  #
  def related_isbns
    []
  end

  # The main and related ISBNs.
  #
  # @return [Array<String>]
  #
  def all_isbns
    [isbn, *related_isbns]
  end

  # The year of publication (:dcterms_dateCopyright or
  # :emma_lastRemediationDate, whichever is earlier).
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  def year
    date_fields.map { |date|
      next unless respond_to?(date)
      value = send(date).to_s.sub(/^(\d{4}).*/, '\1').to_i
      value unless value.zero?
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the first non-blank value given a list of fields.
  #
  # @param [Array<Symbol>] fields
  #
  # @return [String, nil]
  #
  def get_value(*fields)
    get_values(*fields).first
  end

  # Get the first non-empty value given a list of fields.
  #
  # @param [Array<Symbol>] fields
  #
  # @return [Array<String>]
  #
  def get_values(*fields)
    # noinspection RubyYardReturnMatch
    fields.find { |meth|
      values = meth && Array.wrap(try(meth)).compact_blank
      break values.map(&:to_s) if values.present?
    } || []
  end

  # Reduce a string for comparison with another by eliminating characters to
  # ignore for comparison.
  #
  # @param [String] value
  #
  # @return [String]
  #
  def significant(value)
    value.to_s.remove(/[[:space:][:punct:]]/).downcase
  end

end

__loading_end(__FILE__)
