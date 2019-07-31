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

  include ParamsHelper
  include HtmlHelper

  # ===========================================================================
  # :section: Page language
  # ===========================================================================

  public

  # The language code for the language of the current page for use with the
  # "<html>" element.
  #
  # @return [String]
  #
  def page_language
    @page_language ||= I18n.locale.to_s.downcase.sub(/-.*$/, '')
  end

  # Specify the language code for the current page.
  #
  # @param [String, Symbol] lang
  #
  # @return [String]
  #
  # == Usage Notes
  # Only use as an override if the page is in a language that has not been set
  # via I18n::Config#locale.
  #
  def set_page_language(lang)
    @page_language = lang.to_s.downcase.sub(/-.*$/, '')
  end

  # ===========================================================================
  # :section: Page body
  # ===========================================================================

  public

  # Access the classes for the "<body>" element.
  #
  # If a block is given, this invocation is being used to accumulate CSS class
  # names; otherwise this invocation is being used to emit the CSS classes for
  # inclusion in the "<body>" element definition.
  #
  # @return [String]                      If no block given.
  # @return [Array<String>]               If block given.
  #
  def page_classes
    if block_given?
      set_page_classes(*yield)
    else
      emit_page_classes
    end
  end

  # Set the classes for the "<body>" element, eliminating any previous value.
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The current @page_classes contents.
  #
  def set_page_classes(*values)
    @page_classes = []
    @page_classes += values
    @page_classes += Array.wrap(yield) if block_given?
    @page_classes
  end

  # Add to the classes for the "<body>" element.
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The current @page_classes contents.
  #
  def append_page_classes(*values)
    @page_classes ||= default_page_classes
    @page_classes += values
    @page_classes += Array.wrap(yield) if block_given?
    @page_classes
  end

  # Emit the CSS classes for inclusion in the "<body>" element definition.
  #
  # @return [String]
  #
  # == Implementation Notes
  # Invalid CSS name characters are converted to '_'; e.g.:
  # 'user/sessions' -> 'user_sessions'.
  #
  def emit_page_classes
    @page_classes ||= default_page_classes
    @page_classes.flatten!
    @page_classes.reject!(&:blank?)
    @page_classes.map! { |c| c.to_s.gsub(/[^a-z_0-9-]/i, '_') }
    @page_classes.join(' ')
  end

  # default_page_classes
  #
  # @param [Hash] p                   Default: `#params`.
  #
  # @return [Array<String>]
  #
  def default_page_classes(p = nil)
    p ||= defined?(params) ? params : {}
    c = p[:controller].to_s.presence
    a = p[:action].to_s.presence
    result = []
    result << "#{c}-#{a}" if c && a
    result << c           if c
    result << a           if a
    result
  end

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
  # @param [Symbol] mode              Either :text or :image; default: :image.
  # @param [Hash]   opt               Passed to outer #content_tag except for:
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
  def show_nav_bar?(*)
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
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [Hash, nil]           p      Default: `#params`.
  #
  def show_search_bar?(type = nil, p = nil)
    search_input_type(type, p).present?
  end

  # Generate an element for entering search terms.
  #
  # @param [Symbol, String, nil] id     Default: `#search_field_key(type)`
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [Hash]                opt    Passed to #search_form.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If search is not available for *type*.
  #
  def search_bar(id: nil, type: nil, **opt)
    type ||= search_input_type
    id   ||= search_field_key(type)
    opt    = prepend_css_classes(opt, 'search-bar')
    search_form(id, type, **opt) do
      search_input(id, type) + search_button(type)
    end
  end

  # The URL parameter to which search terms should be applied.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  #
  # @return [String]
  #
  def search_field_key(type = nil)
    type ||= search_input_type
    I18n.t(
      "emma.#{type}.search_bar.input.field",
      default: [
        :'emma.search_bar.input.field',
        'keyword'
      ]
    )
  end

  # ===========================================================================
  # :section: Search bar
  # ===========================================================================

  private

  # search_input_type
  #
  # @param [Symbol, String, nil] type   Default: `#params[:controller]`.
  # @param [Hash, nil]           p      Default: `#params`.
  #
  # @return [String]                  The controller used for searching.
  # @return [FalseClass]              If searching should not be enabled.
  #
  def search_input_type(type = nil, p = nil)
    if p
      type ||= p[:controller]
      result =
        I18n.t(
          "emma.#{type}.search_bar.input.enabled",
          default: :'emma.search_bar.input.enabled'
        )
      if true?(result)
        type.to_s
      elsif false?(result)
        false
      else
        result || 'title'
      end
    elsif @search_input_type.nil?
      @search_input_type = search_input_type(type, params)
    else
      @search_input_type
    end
  end

  # Generate a form search field input control.
  #
  # @param [Symbol, String, nil] id     Default: `#search_field_key(type)`
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [String, nil]         value  Default: `#params[id]`.
  # @param [Hash]                opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_input(id = nil, type = nil, value = nil, **opt)
    type ||= search_input_type
    id   ||= search_field_key(type)

    # Screen-reader-only label element.
    label_id = "#{id}-label"
    label = search_input_label(type)
    label = content_tag(:span, label, id: label_id, class: 'sr-only')

    # Input field element.
    opt = prepend_css_classes(opt, 'search-input')
    opt[:'aria-labelledby'] = label_id
    opt[:placeholder] ||= search_input_placeholder(type)
    input = search_field_tag(id, (value || params[id]), opt)

    # Result.
    label + input
  end

  # Generate a form submit control.
  #
  # @param [Symbol, String, nil] type   Default: `#search_input_type`
  # @param [String, nil]         label  Default: `#search_button_label(type)`.
  # @param [Hash]                opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_button(type = nil, label = nil, **opt)
    type  ||= search_input_type
    label ||= search_button_label(type)
    opt = prepend_css_classes(opt, 'search-button')
    submit_tag(label, opt)
  end

  # search_input_label
  #
  # @param [String, Symbol] type
  #
  # @return [String]
  #
  def search_input_label(type)
    I18n.t("emma.#{type}.search_bar.input.label", default: nil) ||
      SEARCH_INPUT_LABEL
  end

  # search_input_placeholder
  #
  # @param [String, Symbol] type
  #
  # @return [String]
  #
  def search_input_placeholder(type)
    I18n.t("emma.#{type}.search_bar.input.placeholder", default: nil) ||
      SEARCH_INPUT_PLACEHOLDER
  end

  # search_button_label
  #
  # @param [String, Symbol] type
  #
  # @return [String]
  #
  def search_button_label(type)
    I18n.t("emma.#{type}.search_bar.button.label", default: nil) ||
      SEARCH_BUTTON_LABEL
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
  # @param [Hash, nil] p              Default: `#params`.
  #
  def show_search_controls?(p = nil)
    p ||= params
    p[:action] == 'index'
  end

  # search_controls
  #
  # @param [Symbol, String, nil] type   Default: `#menu_search_type`
  # @param [Hash]                opt    Passed to #content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def search_controls(type: nil, **opt)
    opt = prepend_css_classes(opt, 'search-controls')
    controls = []
    controls << sort_menu(type: type)
    controls << size_menu(type: type)
    controls << language_menu(type: type)
    controls.reject!(&:blank?)
    content_tag(:div, safe_join(controls, "\n"), opt) if controls.present?
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

  # Sort menus for each controller type that should have a sort menu.
  #
  # @type [Hash{String=>Array<Array<(String,String)>>}]
  #
  SORT_MENU = {
    member:       make_menu(Api::MemberSortOrder),
    periodical:   make_menu(Api::PeriodicalSortOrder),
    reading_list: make_menu(Api::MyReadingListSortOrder),
    title:        make_menu(Api::TitleSortOrder),
  }.stringify_keys.deep_freeze

  # The generic page size menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  GENERIC_SIZE_MENU = make_menu([10, 25, 50, 100]).deep_freeze

  # Page size menus for each controller type that should have a page size menu.
  #
  # @type [Hash{String=>Array<Array<(String,String)>>}]
  #
  SIZE_MENU = {
    category:     GENERIC_SIZE_MENU,
    member:       GENERIC_SIZE_MENU,
    periodical:   GENERIC_SIZE_MENU,
    reading_list: GENERIC_SIZE_MENU,
    title:        GENERIC_SIZE_MENU,
  }.stringify_keys.deep_freeze

  # Patterns matching the names of languages that should not be included in
  # #GENERIC_LANGUAGE_MENU.
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

  # The generic language menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  GENERIC_LANGUAGE_MENU =
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

  # Language menus for each controller type that should have a language menu.
  #
  # @type [Hash{String=>Array<Array<(String,String)>>}]
  #
  LANGUAGE_MENU = {
    periodical: GENERIC_LANGUAGE_MENU,
    title:      GENERIC_LANGUAGE_MENU,
  }.stringify_keys.deep_freeze

  # ===========================================================================
  # :section: Search controls
  # ===========================================================================

  private

  # menu_search_type
  #
  # @param [Symbol, String, nil] type   Default: `#params[:controller]`.
  # @param [Hash, nil]           p      Default: `#params`.
  #
  # @return [String]                  The controller used for searching.
  # @return [FalseClass]              If searching should not be enabled.
  #
  def menu_search_type(type = nil, p = nil)
    if p
      p[:controller]
    elsif @menu_search_type.nil?
      @menu_search_type = menu_search_type(type, params)
    else
      @menu_search_type
    end
  end

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
  # @param [String, nil]         selected  Default: `#params[id]`.
  # @param [Symbol, String, nil] type      Default: `#menu_search_type`
  # @param [Hash]                opt       Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If menu is not available for *type*.
  #
  # @see #SORT_MENU
  # @see #SEARCH_SORT_LABEL
  # @see ParamsConcern#resolve_sort
  #
  # == Implementation Notes
  # This method produces a URL parameter (:sort) which is translated into the
  # appropriate pair of :sortOrder and :direction parameters by #resolve_sort.
  #
  def sort_menu(selected = nil, type: nil, **opt)
    type ||= menu_search_type
    return if (menu = SORT_MENU[type]).blank?
    id  = :sort
    opt = prepend_css_classes(opt, 'sort-menu')
    selected ||= params[id] || params[:sortOrder]
    selected &&= reverse_sort(selected) if params[:direction] == 'desc'
    opt[:label] ||= search_sort_label(type)
    menu_container(id, menu, selected, type, **opt)
  end

  # Perform a search specifying a results page size.
  #
  # @param [String, nil]         selected  Default: `#params[id]`.
  # @param [Symbol, String, nil] type      Default: `#menu_search_type`
  # @param [Hash]                opt       Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If menu is not available for *type*.
  #
  # @see #SIZE_MENU
  # @see #SEARCH_SIZE_LABEL
  #
  def size_menu(selected = nil, type: nil, **opt)
    type ||= menu_search_type
    return if (menu = SIZE_MENU[type]).blank?
    id  = :limit
    opt = prepend_css_classes(opt, 'size-menu')
    selected ||= params[id] || (page_size if defined?(page_size))
    selected &&= selected.to_i
    opt[:label] ||= search_size_label(type)
    menu_container(id, menu, selected, type, **opt)
  end

  # Perform a search limited to the selected language.
  #
  # @param [String, nil]         selected  Default: `#params[id]`.
  # @param [Symbol, String, nil] type      Default: `#menu_search_type`
  # @param [Hash]                opt       Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If menu is not available for *type*.
  #
  # @see #LANGUAGE_MENU
  # @see #SEARCH_LANGUAGE_LABEL
  #
  def language_menu(selected = nil, type: nil, **opt)
    type ||= menu_search_type
    return if (menu = LANGUAGE_MENU[type]).blank?
    id  = :language
    opt = prepend_css_classes(opt, 'language-menu')
    opt[:label] ||= search_language_label(type)
    menu_container(id, menu, selected, type, **opt)
  end

  # ===========================================================================
  # :section: Search controls
  # ===========================================================================

  private

  # search_sort_label
  #
  # @param [String, Symbol] type
  #
  # @return [String]
  #
  def search_sort_label(type)
    I18n.t("emma.#{type}.search_bar.sort.label", default: nil) ||
      SEARCH_SORT_LABEL
  end

  # search_size_label
  #
  # @param [String, Symbol] type
  #
  # @return [String]
  #
  def search_size_label(type)
    I18n.t("emma.#{type}.search_bar.size.label", default: nil) ||
      SEARCH_SIZE_LABEL
  end

  # search_language_label
  #
  # @param [String, Symbol] type
  #
  # @return [String]
  #
  def search_language_label(type)
    I18n.t("emma.#{type}.search_bar.language.label", default: nil) ||
      SEARCH_LANGUAGE_LABEL
  end

  # A menu control preceded by a menu label (if provided).
  #
  # @param [Symbol, String]      id        Associated menu element.
  # @param [Array]               menu      Menu entries.
  # @param [String, nil]         selected  Default: `#params[id]`.
  # @param [Symbol, String, nil] type      Default: `#menu_search_type`
  # @param [Hash]                opt       Passed to #menu_control except for:
  #
  # @option opt [String] :label       If missing, no label is included.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If menu is not available for *type*.
  #
  def menu_container(id, menu, selected = nil, type = nil, **opt)
    label = opt.key?(:label) && (opt = opt.dup).delete(:label)
    menus = menu_control(id, menu, selected, type, **opt)
    return if menus.blank?
    label &&= label_tag(id, label, class: 'menu-label')
    label ||= ''.html_safe
    content_tag(:div, class: 'menu-container') do
      label + menus
    end
  end

  # A dropdown menu element.
  #
  # If no option is currently selected, an initial "null" selection is
  # prepended.
  #
  # @param [Symbol, String]      id
  # @param [Array]               menu       Menu entries.
  # @param [String, nil]         selected   Default: `#params[id]`.
  # @param [Symbol, String, nil] type       Default: `#menu_search_type`.
  # @param [Hash]                opt        Passed to #search_form.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If menu is not available for *type*.
  #
  def menu_control(id, menu, selected = nil, type = nil, **opt)
    return if menu.blank? || (type ||= menu_search_type).blank?
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
    search_form(id, type, **opt) do
      option_tags = options_for_select(menu, selected)
      select_tag(id, option_tags, onchange: 'this.form.submit();')
    end
  end

  # ===========================================================================
  # :section: Search bar and search controls
  # ===========================================================================

  private

  # A form used to create/modify a search.
  #
  # If currently searching for the indicated *type*, then the current URL
  # parameters are included as hidden fields so that the current search is
  # repeated but augmented with the added parameter.  Otherwise a new search is
  # assumed.
  #
  # @param [Symbol, String] id
  # @param [Symbol, String] type
  # @param [Hash]           opt       Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If search is not available for *type*.
  #
  def search_form(id, type, **opt)
    return if (path = search_target(type)).blank?
    opt = opt.merge(method: :get) if opt[:method].blank?
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

  # The target path for searches from the search bar.
  #
  # @param [Symbol, String] type
  # @param [Hash]           opt       Passed to #url_for.
  #
  # @return [String]
  #
  def search_target(type, **opt)
    opt = opt.merge(controller: "/#{type}", action: :index, only_path: true)
    url_for(opt)
  rescue ActionController::UrlGenerationError
    search_target(:title)
  end

  # ===========================================================================
  # :section: Page controls
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show page controls.
  #
  # @param [Hash, nil] p              Default: `#params`.
  #
  def show_page_controls?(p = nil)
    p ||= params
    !p[:controller].to_s.include?('devise')
  end

  # Render the appropriate partial to insert page controls if they are defined
  # for the current controller/action.
  #
  # @param [Hash, nil] p              Default: `#params`.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def render_page_controls(p = nil)
    p ||= params
    partial = p[:action].to_s
    act_al  = Ability::ACTION_ALIAS[partial.to_sym]&.first&.to_s
    partial = act_al if act_al
    partial = "#{p[:controller]}/page_controls/#{partial}"
    render(partial) if partial_exists?(partial)
  end

  # Generate a list of controller/action pairs that the current user is able to
  # perform.
  #
  # @param [Class,Symbol,String] model
  # @param [Array<Symbol>]       actions
  #
  # @return [Array<Array<(Symbol,Symbol)>>]
  #
  def page_control_actions(model, *actions)
    if model.is_a?(Class)
      controller = model.to_s.underscore
    else
      controller = model.to_sym
      model      = model.to_s.camelize.constantize
    end
    actions.map { |action|
      [controller, action] if (action = action&.to_sym) && can?(action, model)
    }.compact
  end

  # Generate controls specified by controller/action pairs generated by
  # #page_controls_actions.
  #
  # @param [Array<Array<(Symbol,Symbol)>>] pairs
  # @param [Hash]                          path_opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def page_controls(*pairs, **path_opt)
    pairs.map { |pair|
      link_to_action(*pair, **path_opt) if pair.present?
    }.compact.join("\n").html_safe.presence
  end

end

__loading_end(__FILE__)
