# app/helpers/title_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# TitleHelper
#
module TitleHelper

  def self.included(base)
    __included(base, '[TitleHelper]')
  end

  include ResourceHelper
  include PaginationHelper
  include ArtifactHelper

  # Default link tooltip.
  #
  # @type [String]
  #
  TITLE_SHOW_TOOLTIP = I18n.t('emma.title.show.tooltip').freeze

  # Default number of results per page if none was specified.
  #
  # @type [Integer]
  #
  DEFAULT_TITLE_PAGE_SIZE = DEFAULT_PAGE_SIZE

  # ===========================================================================
  # :section: PaginationHelper overrides
  # ===========================================================================

  public

  # Default tooltip for item links.
  #
  # @return [String]
  #
  # This method overrides:
  # @see PaginationHelper#default_show_tooltip
  #
  def default_show_tooltip
    TITLE_SHOW_TOOLTIP
  end

  # Default of results per page.
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see PaginationHelper#default_page_size
  #
  def default_page_size
    DEFAULT_TITLE_PAGE_SIZE
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of title results.
  #
  # @return [Array<TitleMetadataSummary>]
  #
  def title_list
    page_items
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Object]              item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash, nil]           opt    @see ResourceHelper#item_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_link(item, label = nil, **opt)
    path = title_path(id: item.identifier)
    item_link(item, label, path, **opt)
  end

  # Thumbnail element for the given catalog title.
  #
  # @param [Api::Common::TitleMethods] item
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no thumbnail.
  #
  def thumbnail(item)
    url = item.respond_to?(:thumbnail_image) && item.thumbnail_image
    image_element(url, 'thumbnail') if url.present?
  end

  # Cover image element for the given catalog title.
  #
  # @param [Api::Common::TitleMethods] item
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no cover image.
  #
  def cover_image(item)
    url = item.respond_to?(:cover_image) && item.cover_image
    image_element(url, 'cover-image') if url.present?
  end

  # Create links to download each artifact of the given item.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #artifact_link
  #
  # @option opt [String] :separator   Default: #DEFAULT_ELEMENT_SEPARATOR.
  # @option opt [String] :type        Limit results to this format.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_links(item, **opt)
    fid = opt[:type]      || opt[:format]
    sep = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    opt = opt.except(:type, :format, :separator)
    item.formats.map { |format|
      next if fid && (fid != format.formatId)
      artifact_link(item, format, opt)
    }.compact.sort.join(sep).html_safe
  end

  # Item categories as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def category_links(item, **opt)
    opt = opt.merge(all_words: true)
    title_search_links(item, :categories, **opt)
  end

  # Item authors as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def author_links(item, **opt)
    title_search_links(item, :author, **opt)
  end

  # Item composers as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def composer_links(item, **opt)
    title_search_links(item, :composer, **opt)
  end

  # Item formats as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def format_links(item, **opt)
    opt = opt.merge(method: :format, all_words: true)
    title_search_links(item, :format, **opt)
  end

  # Item languages as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def language_links(item, **opt)
    opt = opt.merge(all_words: true)
    title_search_links(item, :language, **opt)
  end

  # Item countries as search links.
  #
  # NOTE: This is apparently not working in Bookshare.
  # Although an invalid country code will result in no results, all valid
  # country codes result in the same results.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def country_links(item, **opt)
    opt = opt.merge(all_words: true, no_link: true)
    title_search_links(item, :country, **opt)
  end

  # Item terms as search links.
  #
  # @param [Object]      item
  # @param [Symbol, nil] field        Default: :keyword
  # @param [Hash, nil]   opt          @see #title_search_link
  #
  # @option opt [Symbol, String] :field
  # @option opt [Symbol]         :method
  # @option opt [String]         :separator   Def.: #DEFAULT_ELEMENT_SEPARATOR
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def title_search_links(item, field = nil, **opt)

    field  = opt[:field]  || field || :keyword
    method = opt[:method] || field.to_s.pluralize.to_sym
    return unless item.respond_to?(method)

    sep  = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    opt  = opt.except(:field, :method, :separator)
    null = opt.include?(:no_link).presence
    Array.wrap(item.send(method)).map { |s|
      no_link = null
      no_link ||=
        case field
          when :categories then !s.bookshare_category
        end
      link_opt = no_link ? opt.merge(no_link: no_link) : opt
      title_search_link(s, field, **link_opt)
    }.sort.uniq.join(sep).html_safe

  end

  TITLE_SEARCH_LINK_OPTIONS = %i[field all_words no_link].freeze

  # Create a link to the search results index page for the given term(s).
  #
  # @param [String]                     terms
  # @param [Symbol, Array<Symbol>, nil] field   Default: :keyword
  # @param [Hash, nil]                  opt     @see #link_to
  #
  # @option opt [Symbol]  :field
  # @option opt [Boolean] :all_words
  # @option opt [Boolean] :no_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_search_link(terms, field = nil, **opt)
    terms = terms.to_s
    local = opt.slice(*TITLE_SEARCH_LINK_OPTIONS)
    opt   = opt.except(*TITLE_SEARCH_LINK_OPTIONS)
    field = local[:field] || field || :keyword

    # Generate the link label.
    label =
      if %i[language languages].include?(field)
        ISO_639.find(terms)&.english_name
      end
    label ||= terms

    # If this instance should not be rendered as a link, return now.
    return content_tag(:span, label, **opt) if local[:no_link]

    # Otherwise, wrap the terms phrase in quotes unless directed to handled
    # each word of the phrase separately.
    if local[:all_words]
      words = terms.split(/\s/).compact.map { |t| %Q("#{t}") }
      tip_terms = +''
      tip_terms << 'containing ' if words.size > 1
      tip_terms << words.join(', ')
    else
      tip_terms = terms = %Q("#{terms}")
    end
    opt[:title] =
      I18n.t('emma.title.index.tooltip', terms: "#{field} #{tip_terms}")
    search = Array.wrap(field).map { |f| [f, terms] }.to_h
    link_to(label, title_index_path(search), opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fields from Api::TitleMetadataComplete, Api::TitleMetadataSummary,
  # Api::TitleMetadataDetail, Api::AssignedTitleMetadataSummary.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # Compare with:
  # @see PeriodicalHelper#PERIODICAL_SHOW_FIELDS
  #
  TITLE_SHOW_FIELDS = {

    # === Series title information ===
    Edition:              :edition,
    SeriesTitle:          :seriesTitle,
    SeriesSubtitle:       :seriesSubtitle,
    SeriesNumber:         :seriesNumber,

    # === Music title information ===
    Opus:                 :opus,
    MovementTitle:        :movementTitle,
    MovementNumber:       :movementNumber,
    MusicScoreType:       :musicScoreType,

    # === Additional title information ===
    TitleContentType:     :titleContentType,
    TitleSource:          :titleSource,

    # === Contributors ===
    Authors:              :authors,
    Composers:            :composers,
    Lyricists:            :lyricists,
    Arrangers:            :arrangers,
    Translators:          :translators,

    # === Description ===
    Year:                 :year,
    Languages:            :languages,
    Synopsis:             :synopsis,
    Categories:           :categories,
    Countries:            :countries,

    # === Audience ===
    AdultContent:         :adultContent,
    Grades:               :grades,
    MinReadingAge:        :readingAgeMinimum,
    MaxReadingAge:        :readingAgeMaximum,

    # === Identifiers ===
    ISBN:                 :isbn13,
    RelatedISBNs:         :relatedIsbns,
    ExternalCategoryCode: :externalCategoryCode,

    # === Text information ===
    Images:               :numImages,
    Pages:                :numPages,

    # === Music information ===
    MusicLayout:          :musicLayout,
    Key:                  :key,
    Instruments:          :instruments,
    VocalParts:           :vocalParts,
    HasChordSymbols:      :hasChordSymbols,

    # === Publisher/provider information ===
    PublishDate:          :publishDate,
    Publisher:            :publisher,

    # === Rights ===
    UsageRestriction:     :usageRestriction,
    Copyright:            :copyright,
    CopyrightDate:        :copyrightDate,

    # === Other ===
    Notes:                :notes,

    # === Item instances ===
    Formats:              :formats,
    Artifacts:            :artifacts,
    DtBookSize:           :dtbookSize,

    # === Assignment information ===
    AssignedBy:           :assignedBy,
    DateAdded:            :dateAdded,
    DateDownloaded:       :dateDownloaded,

    # === Bookshare information ===
    BookshareId:          :bookshareId,
    ReplacementId:        :replacementId,
    ContentWarnings:      :contentWarnings,
    Available:            :available,
    Submitter:            :submitter,
    Proofreader:          :proofreader,
    LastUpdatedDate:      :lastUpdatedDate,
    WithdrawalDate:       :withdrawalDate,
    AllowRecommend:       :allowRecommend,
    Links:                :links,

  }.freeze

  # title_field_values
  #
  # @param [Api::Record::Base] item
  # @param [Hash, nil]         opt
  #
  # @return [Hash{Symbol=>Object}]
  #
  def title_field_values(item, **opt)
    field_values(item) do
      TITLE_SHOW_FIELDS.merge(opt).transform_values do |v|
        case v
          when :formats then download_links(item)
          else               v
        end
      end
    end
  end

end

__loading_end(__FILE__)
