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

  # Default link tooltip.
  #
  # @type [String]
  #
  TITLE_SHOW_TOOLTIP = I18n.t('emma.title.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Object]              item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash, nil]           opt    Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_link(item, label = nil, **opt)
    path = title_path(id: item.identifier)
    opt  = opt.merge(tooltip: TITLE_SHOW_TOOLTIP)
    item_link(item, label, path, **opt)
  end

  # Thumbnail element for the given catalog title.
  #
  # @param [Api::Common::TitleMethods] item
  # @param [Hash, nil]                 opt    Passed to #image_element except:
  #
  # @option opt [Boolean] :link           If *true* make the image a link to
  #                                         the show page for the item.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no thumbnail.
  #
  def thumbnail(item, **opt)
    url = item.respond_to?(:thumbnail_image) && item.thumbnail_image
    return if url.blank?
    id  = item.identifier
    opt = prepend_css_classes(opt, 'thumbnail')
    opt[:alt]  ||= I18n.t('emma.title.index.thumbnail.image.alt', item: id)
    opt[:link] &&= title_path(id: id)
    opt[:id] = 'container-img-' + CGI.escapeHTML(id)
    opt[:'data-turbolinks-permanent'] = true
    image_element(url, opt)
  end

  # Cover image element for the given catalog title.
  #
  # @param [Api::Common::TitleMethods] item
  # @param [Hash, nil]                 opt    Passed to #image_element except:
  #
  # @option opt [Boolean] :link           If *true* make the image a link to
  #                                         the show page for the item.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no cover image.
  #
  def cover_image(item, **opt)
    url = item.respond_to?(:cover_image) && item.cover_image
    return if url.blank?
    id  = item.identifier
    opt = prepend_css_classes(opt, 'cover-image')
    opt[:alt]  ||= I18n.t('emma.title.show.cover.image.alt', item: id)
    opt[:link] &&= title_path(id: id)
    image_element(url, opt)
  end

  # Create links to download each artifact of the given item.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            Passed to #artifact_link except for:
  #
  # @option opt [String] :fmt         One of `Api::FormatType.values`
  # @option opt [String] :separator   Default: #DEFAULT_ELEMENT_SEPARATOR.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_links(item, **opt)
    html_opt, opt = extract_options(opt, :fmt, :separator)
    format_id = opt[:fmt]
    separator = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    append_css_classes!(html_opt, 'disabled') if cannot?(:download, Artifact)
    item.formats.map { |format|
      next if format_id && (format_id != format.formatId)
      artifact_link(item, format, html_opt)
    }.compact.sort.join(separator).html_safe
  end

  # Item categories as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # Compare with:
  # PeriodicalHelper#periodical_category_links
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
  # @return [nil]
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
  # @return [nil]
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
  # @return [nil]
  #
  # Compare with:
  # PeriodicalHelper#periodical_format_links
  #
  def format_links(item, **opt)
    opt = opt.merge(all_words: true)
    title_search_links(item, :fmt, **opt)
  end

  # Item languages as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # Compare with:
  # PeriodicalHelper#periodical_language_links
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
  # @return [nil]
  #
  # Compare with:
  # PeriodicalHelper#periodical_country_links
  #
  def country_links(item, **opt)
    opt = opt.merge(all_words: true, no_link: true)
    title_search_links(item, :country, **opt)
  end

  # Catalog item search links.
  #
  # Items in returned in two separately sorted groups: actionable links (<a>
  # elements) followed by items which are not linkable (<span> elements).
  #
  # @param [Object]      item
  # @param [Symbol, nil] field        Default: :keyword
  # @param [Hash, nil]   opt          Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def title_search_links(item, field = nil, **opt)
    field ||= opt[:field] || :keyword
    search_links(item, field, opt.merge(link_method: :title_search_link))
  end

  # A link to the catalog item search results index page for the given term(s).
  #
  # @param [String]      terms
  # @param [Symbol, nil] field        Default: :keyword
  # @param [Hash, nil]   opt          Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def title_search_link(terms, field = nil, **opt)
    field ||= opt[:field] || :keyword
    search_link(terms, field, opt.merge(scope: :title))
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
    Synopsis:             :contents,
    Categories:           :categories,
    Countries:            :countries,

    # === Audience ===
    AdultContent:         :adultContent,
    GradeLevel:           :grades,
    MinReadingAge:        :readingAgeMinimum,
    MaxReadingAge:        :readingAgeMaximum,

    # === Identifiers ===
    ISBN:                 :isbn,
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
    Publisher:            :publisher,
    PublishDate:          :publishDate,

    # === Rights ===
    UsageRestriction:     :usageRestriction,
    Copyright:            :copyright,
    CopyrightDate:        :copyrightDate,

    # === Other ===
    Notes:                :notes,

    # === Assignment information ===
    AssignedBy:           :assignedBy,
    DateAdded:            :dateAdded,
    DateDownloaded:       :dateDownloaded,

    # === Bookshare information ===
    BookshareId:          :bookshareId,
    ReplacementId:        :replacementId,
    ContentWarnings:      :contentWarnings,
    Submitter:            :submitter,
    Proofreader:          :proofreader,
    LastUpdatedDate:      :lastUpdatedDate,
    WithdrawalDate:       :withdrawalDate,
    AllowRecommend:       :allowRecommend,
    Available:            :available,

    # === Item instances ===
    DtBookSize:           :dtbookSize,
    Artifacts:            :artifacts,
    Formats:              :fmts,
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
          when :fmts then download_links(item)
          else            v
        end
      end
    end
  end

end

__loading_end(__FILE__)
