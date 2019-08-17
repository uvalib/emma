# app/models/api/common/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'

require_relative 'link_methods'
require_relative '../name'

# Methods mixed in to record elements related to catalog titles.
#
module Api::Common::TitleMethods

  include Api::Common::LinkMethods

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
    bookshareId.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<String>]
  AUTHOR_TYPES = %w(author coWriter).freeze

  # @type [Array<String>]
  EDITOR_TYPES = %w(editor abridger adapter).freeze

  # @type [Array<String>]
  COMPOSER_TYPES = %w(composer).freeze

  # @type [Array<String>]
  LYRICIST_TYPES = %w(lyricist).freeze

  # @type [Array<String>]
  ARRANGER_TYPES = %w(arranger).freeze

  # @type [Array<String>]
  TRANSLATOR_TYPES = %w(translator).freeze

  # @type [Array<String>]
  CREATOR_TYPES = %w(
    author
    coWriter
    editor
    composer
    arranger
    lyricist
    abridger
    adapter
  ).freeze

  # The author(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def author_list(**opt)
    creator_list(*AUTHOR_TYPES, **opt)
  end

  # The editor(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def editor_list(**opt)
    creator_list(*EDITOR_TYPES, **opt)
  end

  # The composer(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def composer_list(**opt)
    creator_list(*COMPOSER_TYPES, **opt)
  end

  # The lyricist(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def lyricist_list(**opt)
    creator_list(*LYRICIST_TYPES, **opt)
  end

  # The arranger(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def arranger_list(**opt)
    creator_list(*ARRANGER_TYPES, **opt)
  end

  # The translator(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def translator_list(**opt)
    creator_list(*TRANSLATOR_TYPES, **opt)
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
  # @param [Array<ContributorType>] types   Default: `#CREATOR_TYPES`
  # @param [Hash]                   opt
  #
  # @option opt [Boolean] :role       If *true*, append the contributor type.
  #
  # @return [Array<String>]
  #
  # noinspection RubyAssignmentExpressionInConditionalInspection
  def creator_list(*types, **opt)
    types = types.compact.presence || CREATOR_TYPES
    list =
      %i[authors composers lyricists arrangers].flat_map do |field|
        next unless respond_to?(field)
        next unless types.include?(type = field.to_s.singularize)
        values = send(field)
        opt[:role] ? values.map { |v| "#{v} (#{type})" } : values
      end
    list += contributor_list(*types, **opt)
    list.compact.uniq
  end

  # All contributor(s) to this catalog title.
  #
  # @param [Array<ContributorType>] types   Default: `ContributorType#values`
  # @param [Hash]                   opt
  #
  # @option opt [Boolean] :role       If *true*, append the contributor type.
  #
  # @return [Array<String>]
  #
  def contributor_list(*types, **opt)
    return [] unless respond_to?(:contributors)
    types = types.compact.presence
    contributors.map { |c|
      c.label(opt[:role]) if types.nil? || types.include?(c.type)
    }.compact
  end

  # All contributors to this catalog title keyed by contributor type.
  #
  # @param [Array<ContributorType>] roles   Default: `ContributorType#values`
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def contributor_table(*roles)
    return {} unless respond_to?(:contributors)
    roles = roles.compact.presence || ContributorType.values
    roles.map { |role|
      k = role.to_sym
      v = contributors.map { |c| c.label if c.type == role }.compact
      [k, v]
    }.to_h
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
    ti = title.to_s.presence
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
    isbn13 if respond_to?(:isbn13)
  end

  # The year of publication (:publishDate or :copyrightDate, whichever is
  # earlier).
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  def year
    %i[copyrightDate publishDate].map { |date|
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
    %i[synopsis description].find do |method|
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
    get_link(:thumbnail)
  end

  # A link to a title's cover image if present.
  #
  # @return [String]
  # @return [nil]                     If the link was not present.
  #
  def cover_image
    get_link(:coverimage)
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

end

__loading_end(__FILE__)
