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

  # Field(s) that may hold the name of the container/aggregate for an article.
  #
  # @return [Array<Symbol>]
  #
  def journal_title_fields
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

  # One or more title strings.
  #
  # @return [Array<String>]
  #
  def title_values
    get_values(*title_fields)
  end

  # One or more subtitle strings.
  #
  # @return [Array<String>]
  #
  def subtitle_values
    get_values(*subtitle_fields)
  end

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
    ti = title_values&.first
    st = subtitle_values&.first
    if ti && st
      # Remove the automatically-appended subtitle (in the case of search
      # results entries).
      ti = ti.delete_suffix(st).rstrip.delete_suffix(':')
      # Append the subtitle only if it doesn't appear to already be included in
      # the base title itself.
      ti = "#{ti}: #{st}" unless significant(ti).include?(significant(st))
    end
    ti || st || '???'
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The type of work containing an article (if relevant).
  #
  # @return [String, nil]
  #
  def series_type
  end

  # The volume of the journal containing an article (if relevant).
  #
  # @return [String, nil]
  #
  def series_volume
  end

  # The issue of the journal containing an article (if relevant).
  #
  # @return [String, nil]
  #
  def series_issue
  end

  # The volume and/or issue number containing an article (if relevant).
  #
  # @return [String, nil]
  #
  def series_position
    volume = series_volume&.then { |v| "vol. #{v}" }
    issue  = series_issue&.then  { |n| "no. #{n}"  }
    [volume, issue].compact.join(', ') if volume || issue
  end

  # The journal which contains an article (if relevant).
  #
  # @return [String, nil]
  #
  def journal_title
    get_value(*journal_title_fields)
  end

  # The journal which contains an article (if relevant).
  #
  # @return [String, nil]
  #
  def full_journal_title
    title = journal_title
    issue = title && series_position
    issue ? "#{title}, #{issue}" : title
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Name of publisher.
  #
  # @return [String, nil]
  #
  def publisher_name
  end

  # The place of publication.
  #
  # @return [String, nil]
  #
  def publication_place
  end

  # The date of publication.
  #
  # @return [String, nil]
  #
  def publication_date
  end

  # The date of publication.
  #
  # @return [String, nil]
  #
  def publication_year
  end

  # Publisher and/or publisher location
  #
  # @return [String, nil]
  #
  def full_publisher
    pub = publisher_name
    loc = publication_place
    if pub && loc && !significant(pub).include?(significant(loc))
      sep = (',' unless pub.match?(/[[:punct:]]$/))
      pub = "#{pub}#{sep} #{loc}"
    end
    pub || loc
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # language_list
  #
  # @return [Array<String>]
  #
  def language_list
    []
  end

  # subject_list
  #
  # @return [Array<String>]
  #
  def subject_list
    []
  end

  # description_list
  #
  # @return [Array<String>]
  #
  def description_list
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

end

__loading_end(__FILE__)
