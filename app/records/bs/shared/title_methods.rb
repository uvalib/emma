# app/records/bs/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
# Attributes supplied by the including module:
#
# @attr [String]  bookshareId
# @attr [String]  isbn13
# @attr [Integer] numImages
# @attr [Integer] numPages
#
module Bs::Shared::TitleMethods

  include ::TitleMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

  # A unique identifier for this catalog title.
  #
  # @return [String]
  #
  def identifier
    bookshareId.to_s
  end

  # ===========================================================================
  # :section: ::TitleMethods overrides
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
  TRANSLATOR_TYPES = %w(translator transcriber).freeze

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

  # The author(s)/creator(s) of this catalog title.
  #
  # @param [Array<String>] types      Default: `#CREATOR_TYPES`
  # @param [Hash]          opt
  #
  # @option opt [Boolean] :role       If *true*, append the contributor type.
  #
  # @return [Array<String>]
  #
  #--
  # noinspection RubyAssignmentExpressionInConditionalInspection
  #++
  def creator_list(*types, **opt)
    types = types.compact.presence || CREATOR_TYPES
    list =
      %i[authors composers lyricists arrangers].flat_map do |field|
        next unless respond_to?(field)
        next unless types.include?(type = field.to_s.singularize)
        values = send(field) || []
        opt[:role] ? values.map { |v| "#{v} (#{type})" } : values
      end
    list += contributor_list(*types, **opt)
    list.compact.uniq
  end

  # All contributor(s) to this catalog title.
  #
  # @param [Array<String>] types      Default: all
  # @param [Hash]          opt
  #
  # @option opt [Boolean] :role       If *true*, append the contributor type.
  #
  # @return [Array<String>]
  #
  def contributor_list(*types, **opt)
    result = respond_to?(:contributors) && contributors || []
    result = result.select { |c| types.include?(c.type) } if types.present?
    # noinspection RubyNilAnalysis
    result.map { |c| c.label(opt[:role]) }
  end

  # All contributors to this catalog title keyed by contributor type.
  #
  # @param [Array<String>] roles      Default: `ContributorType#values`
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
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

  # The ISBN.
  #
  # @return [String]
  # @return [nil]                     If the value cannot be determined.
  #
  def isbn
    isbn13 if respond_to?(:isbn13)
  end

  # Related ISBNs omitting the main ISBN if part of the data array.
  #
  # @return [Array<String>]
  #
  def related_isbns
    Array.wrap(relatedIsbns).reject(&:blank?).uniq - Array.wrap(isbn)
  end

  # ===========================================================================
  # :section: ::TitleMethods overrides
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
    # noinspection RubyYardReturnMatch
    result
  end

  # The number of pages.
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  def page_count
    count = respond_to?(:numPages) ? numPages.to_i : 0
    count if count.positive?
  end

  # The number of images.
  #
  # @return [Integer]
  # @return [nil]                     If the value cannot be determined.
  #
  def image_count
    count = respond_to?(:numImages) ? numImages.to_i : 0
    count if count.positive?
  end

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

  # Field(s) that may hold the title string.
  #
  # @return [Array<Symbol>]
  #
  def title_fields
    %i[title]
  end

  # Field(s) that may hold the subtitle string.
  #
  # @return [Array<Symbol>]
  #
  def subtitle_fields
    %i[subtitle]
  end

  # Field(s) that may hold date information about the title.
  #
  # @return [Array<Symbol>]
  #
  def date_fields
    %i[copyrightDate publishDate]
  end

  # Field(s) that may hold content information about the title.
  #
  # @return [Array<Symbol>]
  #
  def contents_fields
    %i[synopsis description]
  end

end

__loading_end(__FILE__)
