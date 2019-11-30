# app/records/search/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'

# Methods mixed in to record elements related to catalog titles.
#
module Search::Shared::TitleMethods

  include Search::Shared::LinkMethods

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
    emma_titleId.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The author(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def author_list
    creators
  end

  # The editor(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def editor_list
    []
  end

  # The composer(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def composer_list
    []
  end

  # The lyricist(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def lyricist_list
    []
  end

  # The arranger(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def arranger_list
    []
  end

  # The translator(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def translator_list
    []
  end

  # The creator(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def creators
    creator_list
  end

  # The author(s)/creator(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  # noinspection RubyAssignmentExpressionInConditionalInspection
  def creator_list
    contributor_list
  end

  # All contributor(s) to this catalog title.
  #
  # @return [Array<String>]
  #
  def contributor_list
    # noinspection RubyYardReturnMatch
    respond_to?(:dc_creator) && dc_creator&.compact&.uniq || []
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
  # All artifacts associated with this catalog title.
  #
  # @param [Array<FormatType>] types  Default: `FormatType#values`
  #
  # @return [Array<String>]
  #
  # == Usage Notes
  # Not all record types which include this module actually have an :artifacts
  # property.
  #
  def artifact_list(*types)
    result = respond_to?(:artifacts) && artifacts || []
    result = result.select { |a| types.include?(a.fmt) } if types.present?
    result
  end
=end

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
    ti = dc_title.to_s.presence
    st = respond_to?(:subtitle) && subtitle.to_s.presence
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
    @isbn ||= extract_isbns(dc_identifier).first
  end

  # Related ISBNs omitting the main ISBN if part of the data array.
  #
  # @return [Array<String>]
  #
  def related_isbns
    @related_isbns ||= all_isbns - [isbn]
  end

  # The main and related ISBNs.
  #
  # @return [Array<String>]
  #
  def all_isbns
    @all_isbns ||= extract_isbns(dc_identifier, dc_relation)
  end

  # The year of publication (:dcterms_dateCopyright or
  # :emma_lastRemediationDate, whichever is earlier).
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  def year
    %i[dcterms_dateCopyright emma_lastRemediationDate].map { |date|
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
    %i[dc_description].find do |method|
      next unless respond_to?(method) && (text = send(method)).present?
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
      return CONTENT_SANITIZE.fragment(text).html_safe
    end
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
=begin
    get_link(:thumbnail)
=end
  end

  # A link to a title's cover image if present.
  #
  # @return [String]
  # @return [nil]                     If the link was not present.
  #
  def cover_image
=begin
    get_link(:coverimage)
=end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The number of pages.
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  def page_count
    count = respond_to?(:numPages) ? numPages.to_i : 0
    count if count > 0
  end

  # The number of images.
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  def image_count
    count = respond_to?(:numImages) ? numImages.to_i : 0
    count if count > 0
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Reduce a string for comparision with another by eliminating characters to
  # ignore for comparision.
  #
  # @param [String]
  #
  # @return [String]
  #
  def significant(string)
    string.to_s.gsub(/[[:space:][:punct:]]/, '').downcase
  end

  # Get only ISBN identifiers.
  #
  # @param [Array, String] values
  #
  # @return [Array<String>]
  #
  def extract_isbns(*values)
    extract(:isbn, *values)
  end

  # Get only the specified type of identifier.
  #
  # @param [Symbol, String] type      Type of identifier
  # @param [Array, String]  values
  #
  # @return [Array<String>]
  #
  def extract(type, *values)
    values
      .flatten(1)
      .map { |v| v.to_s.strip.sub!(/^\s*#{type}[^\d]*/i, '') }
      .compact
      .uniq
  end

end

__loading_end(__FILE__)
