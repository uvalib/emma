# app/decorators/search_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base item presenter for "/search" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Search::Record::MetadataRecord, Search::Record::TitleRecord]
#
class SearchDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  #decorator_for search: Search::Api::Record

  @model_type = :search

  # ===========================================================================
  # :section: Definitions shared with SearchesDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BaseDecorator::SharedPathMethods
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include CssHelper

    include BaseDecorator::SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Render a single label/value pair.
    #
    # @param [String, Symbol, nil] label
    # @param [Any, nil]            value
    # @param [Hash]                opt        Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    def render_pair(label, value, **opt)
      return if value.blank?
      opt[:no_code] = true unless opt.key?(:no_code)
      super(label, value, **opt)
    end

    # =========================================================================
    # :section: BaseDecorator::Fields overrides
    # =========================================================================

    public

    # Bridge the gap between "emma.search.record" (which defines the order of
    # display of data fields) and "emma.entry.record.emma_data" (which holds
    # the details about each data field).
    #
    # @param [Symbol]    field
    # @param [Hash, nil] config
    #
    # @return [Hash]
    #
    def field_properties(field, config = nil)
      Field.configuration_for(field).merge(config || {})
    end

    # The defined levels for rendering an item hierarchically.
    #
    # @param [Hash] opt
    #
    # @return [Hash{Symbol=>Array<Symbol,Integer>}]
    #
    def field_levels(**opt)
      Search::Record::TitleRecord::HIERARCHY_PATHS
    end

    # =========================================================================
    # :section: SearchModesHelper overrides
    # =========================================================================

    public

    # Get the display mode for search results.
    #
    # @return [Symbol]
    #
    def results_type
      context[__method__] || h.send(__method__)
    end

    # Get the display style variant for search results.
    #
    # @return [Symbol]
    #
    def search_style
      context[__method__] || h.send(__method__)
    end

    # =========================================================================
    # :section: Item list (index page) support
    # =========================================================================

    public

    # CSS class for the colorization button tray.
    #
    # @type [String]
    #
    STYLE_CONTAINER = 'button-tray'

    # Colorization button configuration template.
    #
    # @type [Hash{Symbol=>String,Symbol}]
    #
    STYLE_BUTTON_TEMPLATE = I18n.t('emma.search.styles._colorize').deep_freeze

    # Colorization buttons.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    STYLE_BUTTONS =
      I18n.t('emma.search.styles').map { |style, prop|
        next if style.start_with?('_')
        prop = prop.dup
        prop[:label] ||= style.to_s

        css = prop[:class].presence || STYLE_BUTTON_TEMPLATE[:class]
        css = css_class_array(css)
        css << style if css.include?(STYLE_BUTTON_TEMPLATE[:class])
        prop[:class] = css_classes(css)

        ident   = prop.delete(:ident).presence
        tooltip = prop.delete(:title).presence || prop[:tooltip].presence
        tooltip %= { ident: ident } if tooltip && ident
        prop.delete(:tooltip) if (prop[:tooltip] = tooltip).blank?

        field = prop[:field]
        field = STYLE_BUTTON_TEMPLATE[:field] if false?(field)
        prop.delete(:field) if (prop[:field] = field).nil?

        prop[:active] = SearchModesHelper.guard_values(prop[:active])

        [style, prop]
      }.compact.to_h.deep_freeze

    # Search result types.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    RESULT_TYPES =
      I18n.t('emma.search.results').map { |style, prop|
        next if style.start_with?('_')
        prop = prop.dup
        prop[:label] ||= style.to_s

        tooltip = prop.delete(:title).presence || prop[:tooltip].presence
        prop.delete(:tooltip) if (prop[:tooltip] = tooltip).blank?

        prop[:active] = SearchModesHelper.guard_values(prop[:active])

        [style, prop]
      }.compact.to_h.deep_freeze

    # Parameters not included in the base path in #search_list_results.
    #
    # @type [Array<Symbol>]
    #
    RESULT_IGNORED_PARAMS =
      (ParamsHelper::IGNORED_PARAMETERS + Paginator::PAGE_PARAMS).uniq.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # In debug mode, add date and volume information to the title line.
    #
    # @type [Boolean]
    #
    SHOW_EXTENDED_TITLE = false

    # Indicate whether items should get extended titles.
    #
    def extended_title?
      SHOW_EXTENDED_TITLE && search_debug?
    end

    # In debug mode, add a display of the (supposed) relevancy score.
    #
    # @note This is probably not very helpful for `results_type == :title`.
    #
    # @type [Boolean]
    #
    SHOW_RELEVANCY_SCORE = false

    # Indicate whether items should show relevancy scores.
    #
    def relevancy_scores?
      SHOW_RELEVANCY_SCORE && search_debug?
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # CSS classes for the current search style.
    #
    # @param [String] suffix
    #
    # @return [Array<String>]
    #
    # @see SearchModesHelper#search_style
    #
    def style_classes(suffix: '-style')
      styles = [search_style]
      styles << :dev if search_debug?
      styles.compact_blank!
      styles.reject! { |v| EngineConcern::RESET_KEYS.include?(v) }
      styles.map! { |v| v.to_s.delete_suffix(suffix) << suffix }
    end

    # CSS classes for the current results mode.
    #
    # @param [String] suffix
    #
    # @return [Array<String>]
    #
    # @see SearchModesHelper#results_type
    #
    def result_classes(suffix: '_results')
      results = [results_type]
      results.compact_blank!
      results.reject! { |v| EngineConcern::RESET_KEYS.include?(v) }
      results.map! { |v| v.to_s.delete_suffix(suffix) << suffix }
    end

  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module SharedInstanceMethods
    include BaseDecorator::SharedInstanceMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module SharedClassMethods
    include BaseDecorator::SharedClassMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module SharedDefinitions
    def self.included(base)
      base.include(SharedInstanceMethods)
      base.extend(SharedClassMethods)
    end
  end

end

class SearchDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: BaseDecorator::Links overrides
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def link(**opt)
    opt[:path] = search_path(id: object.identifier)
    super(**opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [*]         value
  # @param [Symbol, *] field
  # @param [Hash]      opt            Passed to the render method or super.
  #
  # @return [Field::Type]
  # @return [String]
  # @return [nil]
  #
  def render_value(value, field:, **opt)
    if present? && field.is_a?(Symbol)
      case field
        when :dc_title                then title_and_source_logo(**opt)
        when :emma_repositoryRecordId then source_record_link(**opt)
        when :emma_retrievalLink      then source_retrieval_link(**opt)
        else                               field_for(field, value: value)
      end
    end || super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Add date and volume information to the title line.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  #--
  # noinspection RubyMismatchedArgumentType, RailsParamDefResolve
  #++
  def extended_title
    date    = Search::Record::TitleRecord.item_date(object).presence
    parts   = object.try(:all_item_numbers, '&thinsp;|&thinsp;'.html_safe)
    parts ||= Search::Record::TitleRecord.item_number(object).presence
    title   = ERB::Util.h(object.full_title)
    title  << html_span(date,  class: 'item-date')   if date
    title  << html_span(parts, class: 'item-number') if parts
    title
  end

  # Display title of the associated work along with the logo of the source
  # repository.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div for title and to
  #                                     #prev_next_controls.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LogoHelper#repository_source_logo
  #
  def title_and_source_logo(css: '.title', **opt)
    score  = relevancy_scores? && relevancy_scores
    title  = extended_title? && extended_title || object.full_title
    source = object.emma_repository
    source = '' unless EmmaRepository.values.include?(source)
    prepend_css!(opt, css, source)

    elements = []
    elements << html_div(title, opt)
    elements << h.repository_source_logo(source)
    elements << prev_next_controls(**opt)
    elements << score if score.present?
    safe_join(elements)
  end

  # Display title of the associated work along with the source repository.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div for title and to
  #                                     #prev_next_controls.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LogoHelper#repository_source
  #
  def title_and_source(css: '.title', **opt)
    title  = object.full_title
    source = object.emma_repository
    source = nil unless EmmaRepository.values.include?(source)
    prepend_css!(opt, css, source)
    title  = html_div(title, opt)
    name   = source&.titleize || 'LOGO'
    logo   = h.repository_source(object, source: source, name: name)
    ctrl   = prev_next_controls(**opt)
    title << logo << ctrl
  end

  # An element containing controls for moving up and down through the list.
  #
  # @param [String] css       Characteristic CSS class/selector.
  # @param [Hash]   opt       Passed to #prev_record_link and #next_record_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def prev_next_controls(css: '.prev-next', **opt)
    html_div(class: css_classes(css)) do
      prev_record_link(**opt) << next_record_link(**opt)
    end
  end

  # Create a control for jumping to the previous record in the list.
  #
  # @param [Integer] index            Current index.
  # @param [String]  css              Characteristic CSS class/selector.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LinkHelper#icon_button
  # @see file:app/assets/javascripts/feature/scroll.js *scrollToPrev()*
  #
  def prev_record_link(index: nil, css: '.prev', **)
    opt = {}
    if (enabled = index && (index > paginator.first_index))
      opt[:icon]     = UP_TRIANGLE
      opt[:title]    = 'Go to the previous record' # TODO: I18n
      opt[:url]      = '#value-Title-%d' % (index - 1)
    else
      opt[:icon]     = DELTA
      opt[:title]    = 'This is the first record on the page' # TODO: I18n
      opt[:tabindex] = -1
    end
    prepend_css!(opt, css)
    append_css!(opt, 'forbidden') unless enabled
    icon_button(**opt)
  end

  # Create a control for jumping to the next record in the list.
  #
  # @param [Integer] index            Current index.
  # @param [String]  css              Characteristic CSS class/selector.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LinkHelper#icon_button
  # @see file:app/assets/javascripts/feature/scroll.js *scrollToNext()*
  #
  def next_record_link(index: nil, css: '.next', **)
    opt = {}
    if (enabled = index && (index < paginator.last_index))
      opt[:icon]     = DOWN_TRIANGLE
      opt[:title]    = 'Go to the next record' # TODO: I18n
      opt[:url]      = '#value-Title-%d' % (index + 1)
    else
      opt[:icon]     = REVERSE_DELTA
      opt[:title]    = 'This is the last record on the page' # TODO: I18n
      opt[:tabindex] = -1
    end
    prepend_css!(opt, css)
    append_css!(opt, 'forbidden') unless enabled
    icon_button(**opt)
  end

  # Make a clickable link to the display page for the title on the originating
  # repository's web site.
  #
  # @param [Hash] opt     Passed to #record_popup or LinkHelper#external_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def source_record_link(**opt)
    url  = object.record_title_url
    repo = repository_for(object, url)
    if repo == EmmaRepository.default
      record_popup(**opt)
    elsif url.present?
      repo = repo&.titleize || 'source repository'             # TODO: I18n
      opt[:title] ||= "View this item on the #{repo} website." # TODO: I18n
      rid = CGI.unescape(object.emma_repositoryRecordId)
      external_link(rid, url, **opt)
    else
      rid = CGI.unescape(object.emma_repositoryRecordId)
      ERB::Util.h(rid)
    end
  end

  # Make a clickable link to retrieve a remediated file.
  #
  # @param [Hash] opt                   Passed to link method except for:
  #
  # @option opt [String] :label         Link text (default: the URL).
  # @option opt [String] :url           Overrides `item.record_download_url`.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element.
  # @return [nil]                       If no *url* was provided or found.
  #
  # @see RepositoryHelper#emma_retrieval_link
  # @see RepositoryHelper#bs_retrieval_link
  # @see RepositoryHelper#ht_retrieval_link
  # @see RepositoryHelper#ia_retrieval_link
  #
  def source_retrieval_link(**opt)
    url = opt.delete(:url) || object.record_download_url
    url = CGI.unescape(url.to_s)
    return if url.blank?

    repo  = repository_for(object, url)
    label = opt.delete(:label) || url.dup

    # Adjust the link depending on whether the current session is permitted to
    # perform the download.
    permitted = can?(:download, Artifact)
    append_css!(opt, 'sign-in-required') unless permitted

    # Set up the tooltip to be shown before the item has been requested.
    opt[:title] ||=
      if permitted
        fmt     = object.dc_format.to_s.underscore.upcase.tr('_', ' ')
        origin  = repo&.titleize || 'the source repository' # TODO: I18n
        "Retrieve the #{fmt} source from #{origin}."        # TODO: I18n
      else
        tip_key = (h.signed_in?) ? 'disallowed' : 'sign_in'
        tip_key = "emma.download.link.#{tip_key}.tooltip"
        fmt     = object.label
        origin  = repo || EmmaRepository.default
        default = ArtifactDecorator::DOWNLOAD_TOOLTIP
        I18n.t(tip_key, fmt: fmt, repo: origin, default: default)
      end

    opt[:context] ||= context
    case repo&.to_sym
      when :emma            then emma_retrieval_link(object, label, url, **opt)
      when :ace             then ia_retrieval_link(object, label, url, **opt)
      when :internetArchive then ia_retrieval_link(object, label, url, **opt)
      when :hathiTrust      then ht_retrieval_link(object, label, url, **opt)
      when :bookshare       then bs_retrieval_link(object, label, url, **opt)
      else Log.error { "#{__method__}: #{repo.inspect}: unexpected" } if repo
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a metadata listing of a search result item.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details(pairs: nil, **opt)
    opt[:pairs] = model_show_fields.merge(pairs || {})
    super(**opt)
  end

  # details_container
  #
  # @param [Array]         added      Optional elements after the details.
  # @param [Array<Symbol>] skip       Display aspects to avoid.
  # @param [Hash]          opt        Passed to super
  # @param [Proc]          block      Passed to super
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_container(*added, skip: [], **opt, &block)
    skip = Array.wrap(skip)
    added.prepend(cover(placeholder: false)) unless skip.include?(:cover)
    super(*added, **opt, &block)
  end

  # Create a container with the repository ID displayed as a link but acting as
  # a popup toggle button and a popup panel which is initially hidden.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To PopupHelper#inline_popup except:
  #
  # @option opt [Hash] :attr          Options for deferred content.
  # @option opt [Hash] :placeholder   Options for transient placeholder.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/shared/modal-base.js *ModalBase.toggleModal()*
  #
  def record_popup(css: '.record-popup', **opt)
    attr   = opt.delete(:attr)&.dup || {}
    rid    = object.emma_repositoryRecordId
    id     = opt[:'data-iframe'] || attr[:id] || "record-frame-#{rid}"

    opt[:'data-iframe'] = attr[:id] = id
    opt[:title]          ||= 'View this repository record.' # TODO: I18n
    opt[:control]        ||= {}
    opt[:control][:text] ||= ERB::Util.h(rid)

    ph_opt = opt.delete(:placeholder)
    prepend_css!(opt, css)
    inline_popup(**opt) do
      ph_opt = prepend_css(ph_opt, 'iframe', POPUP_DEFERRED_CLASS)
      ph_opt[:'data-path'] = UploadDecorator.show_path(id: rid, modal: true)
      ph_opt[:'data-attr'] = attr.to_json
      ph_txt = ph_opt.delete(:text) || 'Loading record...' # TODO: I18n
      html_div(ph_txt, ph_opt)
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item(pairs: nil, **opt)
    score_data  = (score_values.presence if relevancy_scores?)
    opt[:outer] = opt[:outer]&.merge(score_data) || score_data if score_data
    opt[:wrap]  = PAIR_WRAPPER unless opt.key?(:wrap)
    opt[:pairs] = model_index_fields.merge(pairs || {})
    super(**opt)
  end

  # Include control icons below the entry number.
  #
  # @param [Boolean] toggle           If *true* add item toggle.
  # @param [Boolean] controls         If *true* add edit controls.
  # @param [Hash]    opt              Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item_number(toggle: false, controls: false, **opt)
    return ''.html_safe if blank?

    opt[:inner] = nil if opt[:inner].is_a?(TrueClass)
    opt[:inner] = Array.wrap(opt[:inner]).dup
    opt[:outer] = Array.wrap(opt[:outer]).dup

    item_id = opt.delete(:id)
    if (toggle &&= list_item_toggle(row: opt[:row], id: item_id))
      opt[:inner] << toggle # Visible for narrow screens.
      opt[:outer] << toggle # Visible for wide and medium-width screens.
      opt[:outer].prepend(format_counts) if search_debug?
    end

    if (controls &&= edit_controls)
      opt[:inner] << controls
    end

    super(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate inline edit controls for the search entry.
  #
  # @param [Symbol] type
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def edit_controls(type: Field::DEFAULT_MODEL)
    if (decorator = ModelTypeMap.get(type))
      decorator.controls_for(object, context: context)
    else
      Log.warn("#{__method__}: no decorator for model type #{type.inspect}")
    end ||
      if (decorator = ModelTypeMap.get((type == :upload) ? :entry : :upload)) # TODO: remove after upload -> entry
        decorator.controls_for(object, context: context)
      end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate an element to display a score for the item.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def relevancy_scores
    scores = object.try(:get_scores).presence or return
    scores.compact!
    types = scores.keys.map { |type| type.to_s.delete_suffix('_score') }
    types = [types[0...-1].join(', '), types[-1]].compact_blank.join(' and ')
    tip   = +'This is a guess at the relevancy "score" for this item'
    tip  << " based on its #{types} metadata" if types.present?
    tip  << '.'
    score = scores.values.sum.round
    html_span(score, class: 'item-score', title: tip)
  end

  # Values supporting search result analysis of relevancy scoring.
  #
  # @return [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def score_values
    return {} if blank?
    {
      'data-normalized_title': object.try(:normalized_title),
      'data-sort_date':        object.try(:emma_sortDate),
      'data-pub_date':         object.try(:emma_publicationDate),
      'data-rem_date':         object.try(:rem_remediationDate),
      'data-item_score':       object.try(:total_score, precision: 2),
    }
  end

  # Generate a summary of the number of files per each format associated with
  # this item.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to outer :ul.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def format_counts(css: '.format-counts', **opt)
    prepend_css!(opt, css)
    html_tag(:ul, opt) do
      counts = object&.get_format_counts || {}
      counts.map do |format, count|
        html_tag(:li) do
          count  = html_span(count, class: 'count')
          format = format.try(:titleize).try(:upcase) || '???'
          format = 'AUDIO' if format == 'DAISY AUDIO'
          format = html_span(format, class: 'format')
          count << format
        end
      end
    end
  end

end

__loading_end(__FILE__)
