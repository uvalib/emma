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

  # ===========================================================================
  # :section: Nav bar
  # ===========================================================================

  public

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
  # :section: Nav bar
  # ===========================================================================

  public

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
    opt = prepend_css_classes(opt, 'search-input')
    opt[:placeholder] ||= SEARCH_INPUT_PLACEHOLDER
    value ||= params[id]
    label_tag(id, SEARCH_INPUT_LABEL, class: 'sr-only') +
      search_field_tag(id, value, opt)
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

  # make_menu
  #
  # @param [Class] type               @see Api::EnumType
  #
  # @return [Array<Array<(String,String)>>]
  #
  def self.make_sort_menu(type)
    type.new.values.flat_map do |v|
      value = v.to_s
      label = value
      label = "#{label[0].upcase}#{label[1..-1]}" if label[0] =~ /^[a-z]/
      no_reverse = (label == 'Relevance')
      pairs = []
      pairs << [label, value]
      pairs << ["#{label} (rev)", "#{value}#{REVERSE_SORT}"] unless no_reverse
      pairs
    end
  end

  # @type [Hash{Symbol=>Array<Array<(String,String)>>}]
  SORT_MENU = {
    title:      make_sort_menu(Api::TitleSortOrder),
    member:     make_sort_menu(Api::MemberSortOrder),
    periodical: make_sort_menu(Api::PeriodicalSortOrder)
  }.deep_freeze

  # @type [Array<Array<(String,String)>>]
  SIZE_MENU = %w(10 25 50 100).map { |v| [v, v] }.deep_freeze

  # @type [Array<Array<(String,String)>>]
  LANGUAGE_MENU =
    ISO_639::ISO_639_2.map { |entry|
      label = entry.english_name.sub(/;.*$/, '')
      case label
        when /^Greek, Modern/ then label = 'Greek'
      end
      next if %w(Bliss Klingon Reserved).any? { |s| label.start_with?(s) }
      next if %w(Sign Undetermined).any? { |s| label.start_with?(s) }
      next if %w(language jargon pidgin content).any? { |s| label.include?(s) }
      next if label.include?('(')
      [label, entry.alpha3_bibliographic]
    }.compact.sort.unshift(%w(English eng)).uniq.deep_freeze

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

  # sort_menu
  #
  # @param [String, nil]         selected  Default: `params[id]`.
  # @param [Symbol, String, nil] type      Default: :title.
  # @param [Hash, nil]           opt       Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see ParamsConcern#resolve_sort
  #
  # == Implementation Notes
  #
  #
  def sort_menu(selected = nil, type: :title, **opt)
    id   = :sort
    opt  = prepend_css_classes(opt, 'sort-menu')
    menu = SORT_MENU[type] || [["type: #{type} unexpected", '']]
    selected ||= params[id] || params[:sortOrder]
    selected &&= reverse_sort(selected) if params[:direction] == 'desc'
    label_tag(id, SEARCH_SORT_LABEL, class: 'control-label') +
      menu_control(id, menu, selected, type: type, **opt)
  end

  # size_menu
  #
  # @param [String, nil]         selected  Default: `params[id]`.
  # @param [Symbol, String, nil] type      Default: :title.
  # @param [Hash, nil]           opt       Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def size_menu(selected = nil, type: :title, **opt)
    id   = :limit
    opt  = prepend_css_classes(opt, 'size-menu')
    menu = SIZE_MENU
    label_tag(id, SEARCH_SIZE_LABEL, class: 'control-label') +
      menu_control(id, menu, selected, type: type, **opt)
  end

  # language_menu
  #
  # @param [String, nil]         selected  Default: `params[id]`.
  # @param [Symbol, String, nil] type      Default: :title.
  # @param [Hash, nil]           opt       Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def language_menu(selected = nil, type: :title, **opt)
    id   = :language
    opt  = prepend_css_classes(opt, 'language-menu')
    menu = LANGUAGE_MENU
    label_tag(id, SEARCH_LANGUAGE_LABEL, class: 'control-label') +
      menu_control(id, menu, selected, type: type, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A dropdown menu element.
  #
  # @param [Symbol, String]      id
  # @param [Array]               menu       Menu elements.
  # @param [String, nil]         selected   Default: `params[id]`.
  # @param [Symbol, String, nil] type       Default: :title.
  # @param [Hash, nil]           opt        Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def menu_control(id, menu, selected = nil, type: :title, **opt)
    selected ||= params[id]
    menu = options_for_select(menu, selected.to_s)
    search_form(id, type: type, **opt) do
      select_tag(id, menu, onchange: 'this.form.submit();')
    end
  end

  # A form used to create/modify a search.
  #
  # If currently searching for the indicated *type*, then the current URL
  # parameters are included as hidden fields so that the current search is
  # augmented.  Otherwise a new search is assumed.
  #
  # @param [Symbol, String]      id
  # @param [Symbol, String, nil] type   Default: :title.
  # @param [Hash, nil]           opt    Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_form(id, type: :title, **opt)
    opt  = opt.merge(method: :get) unless opt[:method]
    path = url_for(controller: "/#{type}", action: :index, only_path: true)
    same_path = (path == request.path)
    hidden_fields = same_path ? params.to_unsafe_h.except(id, :start) : {}
    form_tag(path, opt) do
      inner = hidden_fields.map { |k, v| hidden_field_tag(k, v) }
      inner << yield
      safe_join(Array.wrap(inner).flatten)
    end
  end

end

__loading_end(__FILE__)
