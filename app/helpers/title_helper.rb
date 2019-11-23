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

  include PaginationHelper
  include ResourceHelper
  include ArtifactHelper
  include ImageHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of title results.
  #
  # @return [Array<Bs::Record::TitleMetadataSummary>]
  #
  def title_list
    # noinspection RubyYardReturnMatch
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
  # @param [Bs::Api::Record]     item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash]                opt    Passed to #item_link.
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
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt          Passed to #image_element except for:
  #
  # @option opt [Boolean] :link           If *true* make the image a link to
  #                                         the show page for the item.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no thumbnail.
  #
  def thumbnail(item, **opt)
    url = item.respond_to?(:thumbnail_image) && item.thumbnail_image or return
    opt, html_opt = partition_options(opt, *ITEM_ENTRY_OPT)
    row = positive(opt[:row])
    id  = item.identifier
    prepend_css_classes!(html_opt, 'thumbnail')
    html_opt[:alt]  ||= i18n_lookup(nil, 'thumbnail.image.alt', item: id)
    html_opt[:link] &&= title_path(id: id)
    html_opt[:id]     = "container-img-#{id}"
    html_opt[:row]    = row if row
    html_opt[:'data-turbolinks-permanent'] = true
    # noinspection RubyYardParamTypeMatch
    image_element(url, **html_opt)
  end

  # Cover image element for the given catalog title.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt          Passed to #image_element except for:
  #
  # @option opt [Boolean] :link           If *true* make the image a link to
  #                                         the show page for the item.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no cover image.
  #
  def cover_image(item, **opt)
    # @type [String]
    url = item.respond_to?(:cover_image) && item.cover_image
    return if url.blank?
    id  = item.identifier
    opt = prepend_css_classes(opt, 'cover-image')
    opt[:alt] ||= i18n_lookup(nil, 'cover.image.alt', item: id)
    opt[:link] &&= title_path(id: id)
    image_element(url, opt)
  end

  # Item categories as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #title_search_links
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

  # Item author(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def author_links(item, **opt)
    title_search_links(item, :author_list, **opt)
  end

  # Item editor(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def editor_links(item, **opt)
    opt = opt.merge(method_opt: { role: true })
    title_search_links(item, :editor_list, **opt)
  end

  # Item composer(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def composer_links(item, **opt)
    opt = opt.merge(method_opt: { role: true })
    title_search_links(item, :composer_list, **opt)
  end

  # Item narrator(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def narrator_links(item, **opt)
    opt = opt.merge(method_opt: { role: true })
    title_search_links(item, :narrator_list, **opt)
  end

  # Item creator(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #title_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def creator_links(item, **opt)
    opt = opt.merge(method_opt: { role: true })
    title_search_links(item, :creator_list, **opt)
  end

  # Item formats as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #title_search_links
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
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #title_search_links
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
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #title_search_links
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
  # @param [Bs::Api::Record] item
  # @param [Symbol, nil]     field    Default: :keyword
  # @param [Hash]            opt      Passed to #search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def title_search_links(item, field = nil, **opt)
    field ||= opt[:field] || :keyword
    opt = opt.merge(link_method: :title_search_link)
    search_links(item, field, **opt)
  end

  # A link to the catalog item search results index page for the given term(s).
  #
  # @param [String]      terms
  # @param [Symbol, nil] field        Default: :keyword
  # @param [Hash]        opt          Passed to #search_link
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def title_search_link(terms, field = nil, **opt)
    field ||= opt[:field] || :keyword
    opt = opt.merge(scope: :title)
    search_link(terms, field, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Bs::Api::Record] item
  # @param [Object]          value
  #
  # @return [Object]
  #
  # @see ResourceHelper#render_value
  #
  def title_render_value(item, value)
    case field_category(value)
      when :title then title_link(item)
      else             render_value(item, value)
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Fields from Bs::Record::AssignedTitleMetadataSummary,
  # Bs::Record::TitleMetadataComplete, Bs::Record::TitleMetadataSummary,
  # Bs::Message::TitleMetadataDetail.
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
    Editors:              :editors,
    Composers:            :composers,
    Lyricists:            :lyricists,
    Arrangers:            :arrangers,
    Translators:          :translators,

    # === Description ===
    Year:                 :year,
    Synopsis:             :contents,
    Languages:            :languages,
    Categories:           :categories,
    Countries:            :countries,

    # === Audience ===
    AdultContent:         :adultContent,
    GradeLevel:           :grades,
    MinReadingAge:        :readingAgeMinimum,
    MaxReadingAge:        :readingAgeMaximum,

    # === Identifiers ===
    ISBN:                 :isbn,
    RelatedISBNs:         :related_isbns,
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
    MarrakeshAvailable:   :marrakeshAvailable,

    # === Bookshare information ===
    BookshareId:          :bookshareId,
    Site:                 :site,
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
    Artifacts:            :artifact_list,
    Formats:              :download_links,
    Links:                :links,

  }.freeze

  # Render an item metadata listing.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_details(item, **opt)
    item_details(item, :title, TITLE_SHOW_FIELDS.merge(opt))
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Fields from Bs::Record::AssignedTitleMetadataSummary,
  # Bs::Record::TitleMetadataComplete, Bs::Record::TitleMetadataSummary,
  # Bs::Message::TitleMetadataDetail.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # Compare with:
  # @see PeriodicalHelper#PERIODICAL_INDEX_FIELDS
  #
  TITLE_INDEX_FIELDS = {
    Title:   :title,
    Authors: :authors,
    Date:    :year
  }.freeze

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_list_entry(item, **opt)
    item_list_entry(item, :title, TITLE_INDEX_FIELDS.merge(opt))
  end

end

__loading_end(__FILE__)
