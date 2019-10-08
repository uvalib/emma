# app/helpers/layout_helper/search_controls.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/common'

# LayoutHelper::SearchControls
#
module LayoutHelper::SearchControls

  include GenericHelper
  include HtmlHelper
  include I18nHelper
  include PaginationHelper
  include LayoutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # If a :sort parameter value ends with this, it indicates that the sort
  # should be performed in reverse order.
  #
  # @type [String]
  #
  REVERSE_SORT = '_rev'

  # From the values of a subclass of Api::EnumType, generate an array of
  # label/value pairs to be used with #select_tag.
  #
  # @param [Class, Array<String,Numeric>] entries
  #
  # @return [Array<Array<(String,String)>>]
  #
  def self.make_menu(entries)
    entries = entries.values if entries.respond_to?(:values)
    Array.wrap(entries).flat_map do |v|
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
  # noinspection RubyYardParamTypeMatch
  SORT_MENU = {
    member:       make_menu(MemberSortOrder),
    periodical:   make_menu(PeriodicalSortOrder),
    reading_list: make_menu(MyReadingListSortOrder),
    title:        make_menu(TitleSortOrder),
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
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the search controls.
  #
  # @param [Hash, nil] p              Default: `#params`.
  #
  def show_search_controls?(p = nil)
    (p || params)[:action] == 'index'
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
  # :section:
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
  # @return [nil]                     If *value* is blank.
  #
  def reverse_sort(value)
    return if value.blank?
    value.end_with?(REVERSE_SORT) ? value : "#{value}#{REVERSE_SORT}"
  end

  # Perform a search specifying a collation order for the results.
  #
  # @param [String, nil]         selected  Default: `#params[id]`.
  # @param [Symbol, String, nil] type      Default: `#menu_search_type`
  # @param [Hash]                opt       Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                          If menu is not available for *type*.
  #
  # @see #SORT_MENU
  # @see ParamsConcern#resolve_sort
  #
  # == Implementation Notes
  # This method produces a URL parameter (:sort) which is translated into the
  # appropriate pair of :sortOrder and :direction parameters by #resolve_sort.
  #
  def sort_menu(selected = nil, type: nil, **opt)
    type ||= menu_search_type
    menu = SORT_MENU[type]
    return if menu.blank?
    id  = :sort
    opt = prepend_css_classes(opt, 'sort-menu')
    selected ||= params[id] || params[:sortOrder]
    selected &&= reverse_sort(selected) if params[:direction] == 'desc'
    opt[:label] ||= i18n_lookup(type, 'search_bar.sort.label')
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
  #
  def size_menu(selected = nil, type: nil, **opt)
    type ||= menu_search_type
    menu = SIZE_MENU[type]
    return if menu.blank?
    id  = :limit
    opt = prepend_css_classes(opt, 'size-menu')
    selected ||= params[id] || (page_size if respond_to?(:page_size))
    selected &&= selected.to_i
    opt[:label] ||= i18n_lookup(type, 'search_bar.size.label')
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
  #
  def language_menu(selected = nil, type: nil, **opt)
    type ||= menu_search_type
    menu = LANGUAGE_MENU[type]
    return if menu.blank?
    id  = :language
    opt = prepend_css_classes(opt, 'language-menu')
    opt[:label] ||= i18n_lookup(type, 'search_bar.language.label')
    menu_container(id, menu, selected, type, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

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
    local, opt = partition_options(opt, :label)
    menu  = menu_control(id, menu, selected, type, **opt)
    return if menu.blank?
    label = local[:label].presence
    label = label ? label_tag(id, label, class: 'menu-label') : ''.html_safe
    content_tag(:div, class: 'menu-container') do
      label + menu
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
      selected = i18n_lookup(type, "search_bar.#{id}.placeholder", mode: false)
      menu = [[selected, '']] + menu if selected
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

end

__loading_end(__FILE__)
