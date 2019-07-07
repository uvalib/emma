# app/helpers/layout_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper.
#
module LayoutHelper

  def self.included(base)
    __included(base, '[LayoutHelper]')
  end

  include HtmlHelper

  # ===========================================================================
  # :section: Nav bar
  # ===========================================================================

  public

  # Text logo.
  #
  # @type [String]
  #
  LOGO_TEXT =
    I18n.t('emma.logo.text.label', default: :'emma.application.name').freeze

  # Logo image relative asset path.
  #
  # @type [String]
  #
  LOGO_ASSET = I18n.t('emma.logo.image.asset').freeze

  # Logo image alt text.
  #
  # @type [String]
  #
  LOGO_ALT_TEXT = I18n.t('emma.logo.image.alt').freeze

  # Logo tagline.
  #
  # @type [String]
  #
  LOGO_TAGLINE = I18n.t('emma.application.tagline', default: '').freeze

  # The controllers included on the nav bar.
  #
  # @type [Array<Symbol>]
  #
  NAV_BAR_CONTROLLERS = I18n.t('emma.nav_bar.controllers').map(&:to_sym).freeze

  # Default dashboard link label.
  #
  # @type [String]
  #
  DASHBOARD_LABEL = I18n.t('emma.home.dashboard.label').freeze

  # Default dashboard link tooltip.
  #
  # @type [String]
  #
  DASHBOARD_TOOLTIP = I18n.t('emma.home.dashboard.tooltip', default: '').freeze

  # Controller link labels.
  #
  # @type [Hash{Symbol=>String}]
  #
  CONTROLLER_LABEL =
    NAV_BAR_CONTROLLERS.map { |c|
      [c, I18n.t("emma.#{c}.label", default: c.to_s.capitalize)]
    }.to_h.deep_freeze

  # Controller link tooltips.
  #
  # @type [Hash{Symbol=>String}]
  #
  CONTROLLER_TOOLTIP =
    NAV_BAR_CONTROLLERS.map { |c|
      [c, I18n.t("emma.#{c}.tooltip", default: '')]
    }.to_h.deep_freeze

  # ===========================================================================
  # :section: Logo
  # ===========================================================================

  public

  # The application logo.
  #
  # @param [Symbol]    mode           Either :text or :image; default: :image.
  # @param [Hash, nil] opt            Passed to outer #content_tag except for:
  #
  # @option opt [String] :alt         Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def logo_element(mode: :image, **opt)
    opt = prepend_css_classes(opt, 'logo')
    alt = opt.delete(:alt)
    content_tag(:div, opt) do
      link_to(root_path, title: LOGO_TAGLINE) do
        if mode == :text
          LOGO_TEXT
        else
          image = asset_path(LOGO_ASSET)
          alt ||= LOGO_ALT_TEXT
          image_tag(image, alt: alt)
        end
      end
    end
  end

  # ===========================================================================
  # :section: Nav bar
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the nav bar.
  #
  def show_nav_bar?
    true
  end

  # Generate an element containing links for the main page of each controller.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def nav_bar_links

    current_params = url_parameters.except(:limit)
    current_path   = current_base_path = request.path
    current_path  += '?' + current_params.to_param if current_params.present?

    links = []

    # Special entry for the dashboard/welcome screen.
    label = DASHBOARD_LABEL
    path  = dashboard_path
    opt   = { title: DASHBOARD_TOOLTIP }
    links <<
      if path == current_path
        content_tag(:span, label, opt.merge(class: 'active disabled'))
      elsif !current_user
        content_tag(:span, label, opt.merge(class: 'disabled'))
      elsif path == current_base_path
        link_to(label, path, opt.merge(class: 'active'))
      else
        link_to(label, path, opt)
      end

    # Entries for the main page of each controller.
    links +=
      NAV_BAR_CONTROLLERS.map do |controller|
        label = CONTROLLER_LABEL[controller]
        path  = send("#{controller}_index_path")
        opt   = { title: CONTROLLER_TOOLTIP[controller] }
        if path == current_path
          content_tag(:span, label, opt.merge(class: 'active disabled'))
        elsif path == current_base_path
          link_to(label, path, opt.merge(class: 'active'))
        else
          link_to(label, path, opt)
        end
      end

    # Element containing links.
    content_tag(:div, class: 'links') do
      separator = content_tag(:span, '|', class: 'separator')
      safe_join(links, separator).html_safe
    end

  end

  # ===========================================================================
  # :section: Search bar
  # ===========================================================================

  public

  # Default (screen-reader-only) search input label.
  #
  # @type [String]
  #
  SEARCH_INPUT_LABEL = I18n.t('emma.search_bar.input.label').freeze

  # Default search input placeholder text.
  #
  # @type [String]
  #
  SEARCH_INPUT_PLACEHOLDER = I18n.t('emma.search_bar.input.placeholder').freeze

  # Default search form commit button label.
  #
  # @type [String]
  #
  SEARCH_BUTTON_LABEL = I18n.t('emma.search_bar.button.label').freeze

  # ===========================================================================
  # :section: Search bar
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the search bar.
  #
  def show_search_bar?
    true
  end

  # Generate an element for entering search terms.
  #
  # @param [Symbol, String, nil] id     Default: :keyword.
  # @param [Symbol, String, nil] type   Default: :title.
  # @param [Hash, nil]           opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_bar(id = :keyword, type: :title, **opt)
    opt = prepend_css_classes(opt, 'search-bar')
    search_form(id, type: type, **opt) do
      search_input(id) + search_button
    end
  end

  # ===========================================================================
  # :section: Search bar
  # ===========================================================================

  private

  # Generate a form search field input control.
  #
  # @param [Symbol, String, nil] id     Default: :keyword.
  # @param [String, nil]         value  Default: `params[id]`.
  # @param [Hash, nil]           opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_input(id = :keyword, value = nil, **opt)
    # Screen-reader-only label element.
    label_id  = "#{id}-label"
    label_opt = { id: label_id, class: 'sr-only' }
    label = content_tag(:span, SEARCH_INPUT_LABEL, label_opt)
    # Input field element.
    opt = prepend_css_classes(opt, 'search-input')
    opt[:placeholder]       ||= SEARCH_INPUT_PLACEHOLDER
    opt[:'aria-labelledby'] ||= label_id
    input = search_field_tag(id, (value || params[id]), opt)
    # Result.
    label + input
  end

  # Generate a form submit control.
  #
  # @param [String, nil] label  Default: #SEARCH_BUTTON_LABEL.
  # @param [Hash, nil]   opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_button(label = SEARCH_BUTTON_LABEL, **opt)
    opt = prepend_css_classes(opt, 'search-button')
    submit_tag(label, opt)
  end

  # ===========================================================================
  # :section: Search controls
  # ===========================================================================

  public

  # Default search sort label.
  #
  # @type [String]
  #
  SEARCH_SORT_LABEL = I18n.t('emma.search_bar.sort.label').freeze

  # Default search page size label.
  #
  # @type [String]
  #
  SEARCH_SIZE_LABEL = I18n.t('emma.search_bar.size.label').freeze

  # Default search language label.
  #
  # @type [String]
  #
  SEARCH_LANGUAGE_LABEL = I18n.t('emma.search_bar.language.label').freeze

  # If a :sort parameter value ends with this, it indicates that the sort
  # should be performed in reverse order.
  #
  # @type [String]
  #
  REVERSE_SORT = '_rev'

  # ===========================================================================
  # :section: Search controls
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the search controls.
  #
  def show_search_controls?
    (params[:action] == 'index') &&
      %w(title periodical).include?(params[:controller])
  end

  # search_controls
  #
  # @param [Symbol, String, nil] type   Default: :title.
  # @param [Hash, nil]           opt    Passed to #content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_controls(type: :title, **opt)
    opt = prepend_css_classes(opt, 'search-controls')
    content_tag(:div, opt) do
      sort_menu(type: type) + size_menu(type: type) + language_menu(type: type)
    end
  end

  # ===========================================================================
  # :section: Search controls
  # ===========================================================================

  private

  # From the values of a subclass of Api::EnumType, generate an array of
  # label/value pairs to be used with #select_tag.
  #
  # @param [Class, Array<String,Numeric>] type
  #
  # @return [Array<Array<(String,String)>>]
  #
  def self.make_menu(type)
    (type.is_a?(Class) ? type.new.values : type).flat_map do |v|
      label = v.to_s.titleize.squish
      rev   = label.delete('0-9').present? && (label != 'Relevance')
      pairs = []
      pairs << [label, v]
      pairs << ["#{label} (rev)", "#{v}#{REVERSE_SORT}"] if rev
      pairs
    end
  end

  # @type [Hash{Symbol=>Array<Array<(String,String)>>}]
  SORT_MENU = {
    title:      make_menu(Api::TitleSortOrder),
    member:     make_menu(Api::MemberSortOrder),
    periodical: make_menu(Api::PeriodicalSortOrder)
  }.deep_freeze

  # @type [Array<Array<(String,String)>>]
  SIZE_MENU = make_menu([10, 25, 50, 100]).deep_freeze

  # Patterns matching the names of languages that should not be included in
  # #LANGUAGE_MENU.
  #
  # @type [Array<Regexp>]
  #
  BOGUS_LANGUAGE = %w(
    ^Bliss
    ^Klingon
    ^Reserved
    ^Sign
    ^Undetermined
    \\\(
    content
    jargon
    language
    pidgin
  ).map { |term| Regexp.new(term) }.deep_freeze

  # @type [Array<Array<(String,String)>>]
  LANGUAGE_MENU =
    ISO_639::ISO_639_2.map { |entry|
      label = entry.english_name.sub(/;.*$/, '')
      label.sub!(/^Greek, Modern.*$/, 'Greek')
      next if BOGUS_LANGUAGE.any? { |pattern| label.match?(pattern) }
      [label, entry.alpha3_bibliographic]
    }.compact
      .sort
      .unshift(%w(Spanish spa))
      .unshift(%w(English eng))
      .uniq
      .deep_freeze

  # ===========================================================================
  # :section: Search controls
  # ===========================================================================

  private

  # Change :sort value to indicate a reverse sort.
  #
  # @param [String] value
  #
  # @return [String]
  # @return [nil]                     If *value* is *nil*.
  #
  def reverse_sort(value)
    value.end_with?(REVERSE_SORT) ? value : (value + REVERSE_SORT) if value
  end

  # Perform a search specifying a collation order for the results.
  #
  # @param [String, nil]         selected  Default: `params[id]`.
  # @param [Symbol, String, nil] type      Default: :title.
  # @param [Hash, nil]           opt       Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #SORT_MENU
  # @see #SEARCH_SORT_LABEL
  # @see ParamsConcern#resolve_sort
  #
  # == Implementation Notes
  # This method produces a URL parameter (:sort) which is translated into the
  # appropriate pair of :sortOrder and :direction parameters by #resolve_sort.
  #
  def sort_menu(selected = nil, type: :title, **opt)
    id   = :sort
    opt  = prepend_css_classes(opt, 'sort-menu')
    menu = SORT_MENU[type] || [["type: #{type} unexpected", '']]
    selected ||= params[id] || params[:sortOrder]
    selected &&= reverse_sort(selected) if params[:direction] == 'desc'
    opt[:label] ||= SEARCH_SORT_LABEL
    menu_container(id, menu, selected, type: type, **opt)
  end

  # Perform a search specifying a results page size.
  #
  # @param [String, nil]         selected  Default: `params[id]`.
  # @param [Symbol, String, nil] type      Default: :title.
  # @param [Hash, nil]           opt       Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #SIZE_MENU
  # @see #SEARCH_SIZE_LABEL
  #
  def size_menu(selected = nil, type: :title, **opt)
    id   = :limit
    opt  = prepend_css_classes(opt, 'size-menu')
    menu = SIZE_MENU
    selected ||= params[id] || (page_size if defined?(page_size))
    selected &&= selected.to_i
    opt[:label] ||= SEARCH_SIZE_LABEL
    menu_container(id, menu, selected, type: type, **opt)
  end

  # Perform a search limited to the selected language.
  #
  # @param [String, nil]         selected  Default: `params[id]`.
  # @param [Symbol, String, nil] type      Default: :title.
  # @param [Hash, nil]           opt       Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #LANGUAGE_MENU
  # @see #SEARCH_LANGUAGE_LABEL
  #
  def language_menu(selected = nil, type: :title, **opt)
    id   = :language
    opt  = prepend_css_classes(opt, 'language-menu')
    menu = LANGUAGE_MENU
    opt[:label] ||= SEARCH_LANGUAGE_LABEL
    menu_container(id, menu, selected, type: type, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A menu control preceded by a menu label (if provided).
  #
  # @param [Symbol, String]      id        Associated menu element.
  # @param [Array]               menu      Menu entries.
  # @param [String, nil]         selected  Default: `params[id]`.
  # @param [Symbol, String, nil] type      Default: `params[:controller]`.
  # @param [Hash, nil]           opt       Passed to #menu_control except for:
  #
  # @option opt [String] :label       If missing, no label is included.
  #
  def menu_container(id, menu, selected = nil, type: :current, **opt)
    label = opt.key?(:label) && (opt = opt.dup).delete(:label)
    content_tag(:div, class: 'menu-container') do
      parts = []
      parts << label_tag(id, label, class: 'menu-label') if label.present?
      parts << menu_control(id, menu, selected, type: type, **opt)
      safe_join(parts)
    end
  end

  # A dropdown menu element.
  #
  # If no option is currently selected, an initial "null" selection is
  # prepended.
  #
  # @param [Symbol, String]      id
  # @param [Array]               menu       Menu entries.
  # @param [String, nil]         selected   Default: `params[id]`.
  # @param [Symbol, String, nil] type       Default: `params[:controller]`.
  # @param [Hash, nil]           opt        Passed to #search_form.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def menu_control(id, menu, selected = nil, type: :current, **opt)
    opt = prepend_css_classes(opt, 'menu-control')
    selected ||= params[id]
    if selected.blank?
      selected = I18n.t("emma.search_bar.#{id}.placeholder", default: nil)
      menu = [%W(#{selected} '')] + menu if selected
    elsif menu.none? { |pair| pair.last == selected }
      label = selected.to_s.titleize.squish
      menu += [[label, selected]]
      if selected.is_a?(String)
        menu.sort!
      else
        menu.sort_by!(&:last)
      end
    end
    search_form(id, type: type, **opt) do
      option_tags = options_for_select(menu, selected)
      select_tag(id, option_tags, onchange: 'this.form.submit();')
    end
  end

  # A form used to create/modify a search.
  #
  # If currently searching for the indicated *type*, then the current URL
  # parameters are included as hidden fields so that the current search is
  # repeated but augmented with the added parameter.  Otherwise a new search is
  # assumed.
  #
  # @param [Symbol, String]      id
  # @param [Symbol, String, nil] type   Default: `params[:controller]`.
  # @param [Hash, nil]           opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_form(id, type: :current, **opt)
    opt  = opt.merge(method: :get) if opt[:method].blank?
    type = params[:controller] if type == :current
    path = url_for(controller: "/#{type}", action: :index, only_path: true)
    hidden_fields =
      if path == request.path
        request_parameters.except(id, :offset, :start).map do |k, v|
          hidden_field_tag(k, v, id: "#{id}-#{k}")
        end
      end
    form_tag(path, opt) do
      fields = hidden_fields || []
      fields << yield
      safe_join(Array.wrap(fields).flatten)
    end
  end

  # ===========================================================================
  # :section: # TODO: move to ResourceHelper
  # ===========================================================================

  public

  # Active search terms.
  #
  # @param [Hash, nil]                 pairs    Default: `#url_parameters`.
  # @param [Symbol, Array<Symbol, nil] only
  # @param [Symbol, Array<Symbol, nil] except
  #
  # @return [Hash{String=>String}]
  #
  def search_terms(pairs = nil, only: nil, except: nil)
    only   = Array.wrap(only).presence
    except = Array.wrap(except) + %i[offset start limit api_key]
    pairs ||= url_parameters
    pairs.slice!(*only)    if only
    pairs.except!(*except) if except
    pairs.map { |k, v|
      plural = v.is_a?(Enumerable) && (v.size > 1)
      field  = labelize(k)
      field  = (plural ? field.pluralize : field.singularize).html_safe
      value  = v.to_s.sub(/^\s*(["'])(.*)\1\s*$/, '\2').inspect
      [field, value]
    }.to_h
  end

  # A control displaying the currently-applied search terms in the current
  # scope (by default).
  #
  # @param [Hash, nil] term_list      Default: `#search_terms`.
  # @param [Hash, nil] opt            Passed to the innermost :content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def applied_search_terms(term_list = nil, **opt)
    opt = prepend_css_classes(opt, 'term')
    leader = 'Search terms:' # TODO: I18n
    leader &&= content_tag(:div, leader, class: 'label')
    separator = content_tag(:span, ';', class: 'term-separator')
    terms =
      (term_list || search_terms).map do |field, value|
        label = content_tag(:span, field, class: 'field')
        sep   = content_tag(:span, ':',   class: 'separator')
        value = content_tag(:span, value, class: 'value')
        content_tag(:div, (label + sep + value), opt)
      end
    content_tag(:div, class: 'applied-search-terms') do
      content_tag(:div, class: 'search-terms') do
        leader + safe_join(terms, separator)
      end
    end
  end
end

__loading_end(__FILE__)
