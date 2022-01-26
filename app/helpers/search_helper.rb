# app/helpers/search_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting access and linkages to the
# "EMMA Unified Search" API.
#
module SearchHelper

  include CssHelper
  include LogoHelper
  include ModelHelper
  include PaginationHelper
  include RepositoryHelper
  include UploadHelper
  include PopupHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default link tooltip.
  #
  # @type [String]
  #
  SEARCH_SHOW_TOOLTIP = I18n.t('emma.search.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_item_link(item, **opt)
    opt[:path]    = search_path(id: item.identifier)
    opt[:tooltip] = SEARCH_SHOW_TOOLTIP
    model_link(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

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

  # Add date and volume information to the title line.
  #
  # @param [Search::Api::Record] item
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  #--
  # noinspection RubyMismatchedArgumentType, RailsParamDefResolve
  #++
  def extended_title(item)
    date    = Search::Record::TitleRecord.item_date(item).presence
    parts   = item.try(:all_item_numbers, '&thinsp;|&thinsp;'.html_safe)
    parts ||= Search::Record::TitleRecord.item_number(item).presence
    title   = ERB::Util.h(item.full_title)
    title  << html_span(date,  class: 'item-date')   if date
    title  << html_span(parts, class: 'item-number') if parts
    title
  end

  # In debug mode, add a display of the (supposed) relevancy score.
  #
  # @note This is probably not very helpful for `search_results == :title`.
  #
  # @type [Boolean]
  #
  SHOW_RELEVANCY_SCORE = false

  # Indicate whether items should show relevancy scores.
  #
  def relevancy_scores?
    SHOW_RELEVANCY_SCORE && search_debug?
  end

  # Generate an element to display a score for the item.
  #
  # @param [Search::Api::Record] item
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def relevancy_scores(item)
    # noinspection RailsParamDefResolve
    scores = item.try(:get_scores).presence or return
    scores.compact!
    types = scores.keys.map { |type| type.to_s.delete_suffix('_score') }
    types = [types[0...-1].join(', '), types[-1]].compact_blank.join(' and ')
    tip   = +'This is a guess at the relevancy "score" for this item'
    tip  << " based on its #{types} metadata" if types.present?
    tip  << '.'
    score = scores.values.sum.round
    html_span(score, class: 'item-score', title: tip)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Upload, Model, Hash] item
  # @param [Any]                 value
  # @param [Symbol]              field
  # @param [Hash]                opt    Passed to the render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  # @see ModelHelper::List#render_value
  # @see UploadHelper#upload_render_value
  #
  def search_render_value(item, value, field: nil, **opt)
    value = field || value
    if item.is_a?(Model) && value.is_a?(Symbol)
      # noinspection RubyMismatchedArgumentType
      # noinspection RubyCaseWithoutElseBlockInspection
      case value
        when :dc_title                then title_and_source_logo(item, **opt)
        when :emma_repositoryRecordId then source_record_link(item, **opt)
        when :emma_retrievalLink      then source_retrieval_link(item, **opt)
      end
    end || upload_render_value(item, value, **opt)
  end

  # Display title of the associated work along with the logo of the source
  # repository.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #html_div for title and to
  #                                       #prev_next_controls.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_and_source_logo(item, **opt)
    css_selector = '.title'
    score  = relevancy_scores? && relevancy_scores(item)
    title  = extended_title? && extended_title(item) || item.full_title
    source = item.emma_repository
    source = '' unless EmmaRepository.values.include?(source)
    prepend_classes!(opt, css_selector, source)

    elements = []
    elements << html_div(title, opt)
    elements << repository_source_logo(source)
    elements << prev_next_controls(**opt)
    elements << score if score.present?
    safe_join(elements)
  end

  # Display title of the associated work along with the source repository.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #html_div for title and to
  #                                       #prev_next_controls.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_and_source(item, **opt)
    css_selector = '.title'
    title  = item.full_title
    source = item.emma_repository
    source = nil unless EmmaRepository.values.include?(source)
    prepend_classes!(opt, css_selector, source)
    title  = html_div(title, opt)
    name   = source&.titleize || 'LOGO'
    logo   = repository_source(item, source: source, name: name)
    ctrl   = prev_next_controls(**opt)
    # noinspection RubyMismatchedReturnType
    title << logo << ctrl
  end

  # An element containing controls for moving up and down through the list.
  #
  # @param [Hash] opt   Passed to #prev_record_link and #next_record_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def prev_next_controls(**opt)
    css_selector = '.prev-next'
    html_div(class: css_classes(css_selector)) do
      prev_record_link(**opt) << next_record_link(**opt)
    end
  end

  # Create a control for jumping to the previous record in the list.
  #
  # @param [Integer, #to_i]      index      Current index.
  # @param [Integer, #to_i, nil] min_index  Default: 0.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/scroll.js *scrollToPrev()*
  #
  def prev_record_link(index: nil, min_index: nil, **)
    css_selector = '.prev'
    index     = positive(index)     || 0
    min_index = positive(min_index) || 0
    opt = {}
    if index > min_index
      opt[:icon]     = UP_TRIANGLE
      opt[:title]    = 'Go to the previous record' # TODO: I18n
      opt[:url]      = '#value-Title-%d' % (index - 1)
    else
      opt[:icon]     = DELTA
      opt[:title]    = 'This is the first record on the page' # TODO: I18n
      opt[:tabindex] = -1
      append_classes!(opt, 'forbidden')
    end
    prepend_classes!(opt, css_selector)
    icon_button(**opt)
  end

  # Create a control for jumping to the next record in the list.
  #
  # @param [Integer, #to_i]      index      Current index.
  # @param [Integer, #to_i, nil] max_index  Default: 1<<32.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/scroll.js *scrollToNext()*
  #
  def next_record_link(index: nil, max_index: nil, **)
    css_selector = '.next'
    index     = positive(index) || 0
    max_index = max_index&.to_i
    max_index = (1 << 32) unless max_index && (max_index >= 0)
    opt = {}
    if index < max_index
      opt[:icon]     = DOWN_TRIANGLE
      opt[:title]    = 'Go to the next record' # TODO: I18n
      opt[:url]      = '#value-Title-%d' % (index + 1)
    else
      opt[:icon]     = REVERSE_DELTA
      opt[:title]    = 'This is the last record on the page' # TODO: I18n
      opt[:tabindex] = -1
      append_classes!(opt, 'forbidden')
    end
    prepend_classes!(opt, css_selector)
    icon_button(**opt)
  end

  # Make a clickable link to the display page for the title on the originating
  # repository's web site.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #record_popup or #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #bs_link?
  #
  def source_record_link(item, **opt)
    url  = item.record_title_url
    repo = url_repository(url) || item.emma_repository.presence
    if repo == EmmaRepository.default
      record_popup(item, **opt)
    elsif url.present?
      repo = repo&.titleize || 'source repository'             # TODO: I18n
      opt[:title] ||= "View this item on the #{repo} website." # TODO: I18n
      rid = CGI.unescape(item.emma_repositoryRecordId)
      external_link(rid, url, **opt)
    else
      rid = CGI.unescape(item.emma_repositoryRecordId)
      ERB::Util.h(rid)
    end
  end

  # Make a clickable link to retrieve a remediated file.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #make_link except for:
  #
  # @option opt [String] :label         Link text (default: the URL).
  # @option opt [String] :url           Overrides `item.record_download_url`.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element.
  # @return [nil]                       If no *url* was provided or found.
  #
  # @see #bs_link?
  #
  def source_retrieval_link(item, **opt)
    opt, html_opt = partition_hash(opt, :label, :url)
    url = opt[:url] || item.record_download_url
    url = CGI.unescape(url.to_s)
    return if url.blank?

    label = opt[:label] || url.dup

    # Adjust the link depending on whether the current session is permitted to
    # perform the download.
    permitted = can?(:download, Artifact)
    append_classes!(html_opt, 'sign-in-required') unless permitted

    # To account for the handful of "EMMA" items that are actually Bookshare
    # items from the "EMMA collection", change the reported repository based on
    # the nature of the URL.
    repo = url_repository(url) || item.emma_repository.presence

    # Set up the tooltip to be shown before the item has been requested.
    html_opt[:title] ||=
      if permitted
        fmt     = item.dc_format.to_s.underscore.upcase.tr('_', ' ')
        origin  = repo&.titleize || 'the source repository' # TODO: I18n
        "Retrieve the #{fmt} source from #{origin}."        # TODO: I18n
      else
        tip_key = (signed_in?) ? 'disallowed' : 'sign_in'
        tip_key = "emma.download.link.#{tip_key}.tooltip"
        fmt     = item.label
        origin  = repo || EmmaRepository.default
        default = ArtifactHelper::DOWNLOAD_TOOLTIP
        I18n.t(tip_key, fmt: fmt, repo: origin, default: default)
      end

    case repo&.to_sym
      when :emma
        emma_retrieval_link(item, label, url, **html_opt)
      when :bookshare
        bs_retrieval_link(item, label, url, **html_opt)
      when :hathiTrust
        ht_retrieval_link(item, label, url, **html_opt)
      when :internetArchive
        ia_retrieval_link(item, label, url, **html_opt)
      else
        Log.error { "#{__method__}: #{repo.inspect}: unexpected" } if repo
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The defined levels for rendering an item hierarchically.
  #
  # @return [Hash{Symbol=>Array<Symbol,Integer>}]
  #
  # == Usage Notes
  # This is invoked from ModelHelper::Fields#field_levels.
  #
  def search_field_levels(**)
    Search::Record::TitleRecord::HIERARCHY_PATHS
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # CSS classes for the current #search_style.
  #
  # @param [String] suffix
  #
  # @return [Array<String>]
  #
  def search_style_classes(suffix: '-style')
    styles = [search_style]
    styles << :dev if search_debug?
    styles.compact_blank!
    styles.reject! { |v| EngineConcern::RESET_KEYS.include?(v) }
    styles.map! { |v| v.to_s.delete_suffix(suffix) << suffix }
  end

  # CSS classes for the current #search_results.
  #
  # @param [String] suffix
  #
  # @return [Array<String>]
  #
  def search_result_classes(suffix: '_results')
    results = [search_results]
    results.compact_blank!
    results.reject! { |v| EngineConcern::RESET_KEYS.include?(v) }
    results.map! { |v| v.to_s.delete_suffix(suffix) << suffix }
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing for a search result item.
  #
  # @param [Search::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_details.
  #
  def search_item_details(item, pairs: nil, **opt)
    opt[:model] = model = :search
    opt[:pairs] = Model.show_fields(model).merge(pairs || {})
    model_details(item, **opt)
  end

  # Create a container with the repository ID displayed as a link but acting as
  # a popup toggle button and a popup panel which is initially hidden.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #popup_container except for:
  #
  # @option opt [Hash] :attr            Options for deferred content.
  # @option opt [Hash] :placeholder     Options for transient placeholder.
  #
  # @see file:app/assets/javascripts/feature/popup.js *togglePopup()*
  #
  def record_popup(item, **opt)
    css_selector = '.record-popup'
    ph_opt = opt.delete(:placeholder)
    attr   = opt.delete(:attr)&.dup || {}
    rid    = item.emma_repositoryRecordId
    id     = opt[:'data-iframe'] || attr[:id] || "record-frame-#{rid}"

    opt[:'data-iframe'] = attr[:id] = id
    opt[:title]   ||= 'View this repository record.' # TODO: I18n
    opt[:control] ||= { text: ERB::Util.h(rid) }

    popup_container(**prepend_classes!(opt, css_selector)) do
      ph_opt = prepend_classes(ph_opt, 'iframe', POPUP_DEFERRED_CLASS)
      ph_txt = ph_opt.delete(:text) || 'Loading record...' # TODO: I18n
      ph_opt[:'data-path'] = show_upload_path(id: rid, modal: true)
      ph_opt[:'data-attr'] = attr.to_json
      html_div(ph_txt, ph_opt)
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # CSS class for the colorization button tray.
  #
  # @type [String]
  #
  SEARCH_STYLE_CONTAINER = 'button-tray'

  # Colorization button configuration template.
  #
  # @type [Hash{Symbol=>String,Symbol}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  SEARCH_STYLE_BUTTON_TEMPLATE =
    I18n.t('emma.search.styles._colorize').deep_freeze

  # Colorization buttons.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  SEARCH_STYLE_BUTTONS =
    I18n.t('emma.search.styles').map { |style, prop|
      next if style.start_with?('_')
      prop = prop.dup
      prop[:label] ||= style.to_s

      css = prop[:class].presence || SEARCH_STYLE_BUTTON_TEMPLATE[:class]
      css = css_class_array(css)
      css << style if css.include?(SEARCH_STYLE_BUTTON_TEMPLATE[:class])
      prop[:class] = css_classes(css)

      ident   = prop.delete(:ident).presence
      tooltip = prop.delete(:title).presence || prop[:tooltip].presence
      tooltip %= { ident: ident } if tooltip && ident
      prop.delete(:tooltip) if (prop[:tooltip] = tooltip).blank?

      field = prop[:field]
      field = SEARCH_STYLE_BUTTON_TEMPLATE[:field] if false?(field)
      prop.delete(:field) if (prop[:field] = field).nil?

      prop[:active] = LayoutHelper::SearchFilters.guard_values(prop[:active])

      [style, prop]
    }.compact.to_h.deep_freeze

  # Controls for applying one or more search style variants.
  #
  # @param [Hash] opt                 Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # @see #SEARCH_STYLE_BUTTONS
  # @see file:app/assets/javascripts/controllers/search.js *setupColorizeButtons()*
  #
  # == Usage Notes
  # This is invoked from ModelHelper::List#page_styles.
  #
  def search_page_styles(**opt)
    common_opt = { class: 'style-button' }
    buttons =
      SEARCH_STYLE_BUTTONS.values.map { |prop|
        next unless permitted_by?(prop[:active])
        button_opt = common_opt.merge(title: prop[:tooltip])
        prepend_classes!(button_opt, prop[:class])
        html_button(prop[:label], button_opt)
      }.compact
    return unless buttons.present?
    prepend_classes!(opt, SEARCH_STYLE_CONTAINER)
    html_div(buttons, **opt)
  end

  # Search result types.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  SEARCH_RESULT_TYPES =
    I18n.t('emma.search.results').map { |style, prop|
      next if style.start_with?('_')
      prop = prop.dup
      prop[:label] ||= style.to_s

      tooltip = prop.delete(:title).presence || prop[:tooltip].presence
      prop.delete(:tooltip) if (prop[:tooltip] = tooltip).blank?

      prop[:active] = LayoutHelper::SearchFilters.guard_values(prop[:active])

      [style, prop]
    }.compact.to_h.deep_freeze

  # Parameters not included in the base path in #search_page_results.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_RESULT_IGNORED_PARAMS =
    UploadConcern::UPLOAD_PAGE_PARAMS || EntryConcern::ENTRY_PAGE_PARAMS

  # Control for selecting the type of search results to display.
  #
  # @param [String,Symbol,nil] selected  Selected menu item.
  # @param [Hash]              opt       Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #SEARCH_RESULT_TYPES
  #
  # == Usage Notes
  # This is invoked from ModelHelper::List#page_results.
  #
  def search_page_results(selected: nil, **opt)
    css_selector = '.results.single.menu-control'
    base_path    = request.path
    url_params   = url_parameters.except(*SEARCH_RESULT_IGNORED_PARAMS)
    prm_selected = url_params.delete(:results)
    selected   ||= prm_selected || search_results
    default      = nil
    pairs =
      SEARCH_RESULT_TYPES.map { |type, prop|
        next unless permitted_by?(prop[:active])
        default = type if prop[:default]
        [prop[:label], type]
      }.compact
    opt[:'data-path'] = make_path(request.path, **url_params)
    prepend_classes!(opt, css_selector)
    html_div(**opt) do
      menu_name   = :results
      option_tags = options_for_select(pairs, selected)
      select_opt  = { id: unique_id(menu_name) }
      select_opt[:'data-default'] = default if default
      select_tag(menu_name, option_tags, select_opt)
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Model, nil] item
  # @param [Hash, nil]  pairs         Additional field mappings.
  # @param [Hash]       opt           Passed to #model_list_item.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_list_item(item, pairs: nil, **opt)
    opt[:model] = :search
    if item
      # noinspection RailsParamDefResolve
      if relevancy_scores?
        added = item.try(:get_scores, precision: 2, all: true) || {}
        added[:sort_date] = item.try(:emma_sortDate).presence
        added[:pub_date]  = item.try(:emma_publicationDate).presence
        added[:rem_date]  = item.try(:rem_remediationDate).presence
        added.transform_values! { |score| score || EMPTY_VALUE }
        pairs = pairs&.merge(added) || added
      end
      # noinspection RubyNilAnalysis
      opt[:pairs]    = pairs || {}             if item.aggregate?
      opt[:render] ||= :render_field_hierarchy if title_results?
    end
    opt[:pairs] ||= Model.index_fields(opt[:model]).merge(pairs || {})
    model_list_item(item, **opt)
  end

  # Include edit and delete controls below the entry number.
  #
  # @param [Model, nil] item
  # @param [Boolean]    edit
  # @param [Hash]       opt               Passed to #list_item_number except:
  #
  # @option opt [String] :id              HTML ID of the item element.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* or *index* is *nil*.
  #
  # @see UploadHelper#upload_edit_icon
  # @see UploadHelper#upload_delete_icon
  #
  def search_list_item_number(item, edit: true, **opt)
    return unless item
    opt[:inner] = nil if opt[:inner].is_a?(TrueClass)
    opt[:inner] = Array.wrap(opt[:inner]).dup
    opt[:outer] = Array.wrap(opt[:outer]).dup
    item_id     = opt.delete(:id)

    if title_results?
      button = search_list_item_toggle(row: opt[:row], id: item_id)
      opt[:inner] << button # Visible for narrow screens.
      opt[:outer] << button # Visible for wide and medium-width screens.
      # noinspection RubyMismatchedArgumentType
      opt[:outer].prepend(format_counts(item)) if search_debug?
    end

    if edit && can?(:modify, item)
      db_id =
        Upload.id_for(item) ||
          if (sid = Upload.sid_for(item))
            Upload.where(submission_id: sid).first&.id
          end
      # noinspection RubyMismatchedArgumentType
      opt[:inner] << upload_entry_icons(item, id: db_id) if db_id.present?
    end

    list_item_number(item, **opt)
  end

  # Generate a summary of the number of files per each format associated with
  # this item.
  #
  # @param [Search::Record::TitleRecord, nil] item
  # @param [Hash]                             opt   Passed to outer :ul.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def format_counts(item, **opt)
    css_selector = '.format-counts'
    html_tag(:ul, prepend_classes!(opt, css_selector)) do
      counts = item&.get_format_counts || {}
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

  # search_list_item_toggle
  #
  # @param [Integer] row
  # @param [Hash]    opt              Passed to #tree_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/controllers/search.js setupToggleControl()
  #
  def search_list_item_toggle(row: nil, **opt)
    if (row = positive(row))
      row = "row-#{row}"
      prepend_classes!(opt, row)
      opt[:'data-row'] ||= ".#{row}"
    end
    opt[:context] ||= :item
    tree_button(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
