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
  include ParamsHelper
  include PaginationHelper
  include LayoutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods

    # The names and properties of all of the search control menus and default
    # values.
    #
    # @type [Hash]
    #
    # noinspection RailsI18nInspection
    SEARCH_MENU_RAW = I18n.t('emma.search_controls')

    # The value 'emma.search_controls._default' contains each of the properties
    # that can be expressed for a menu.  If a property there has a non-nil
    # value, then that value is used as the default for that property.
    #
    # @type [Hash]
    #
    SEARCH_MENU_DEFAULT =
      SEARCH_MENU_RAW[:_default].reject { |_, v| v.nil? }.deep_freeze

    # The names and properties of all of the search control menus.
    #
    # @type [Hash]
    #
    # noinspection RailsI18nInspection
    SEARCH_MENU =
      SEARCH_MENU_RAW.map { |type, values|
        next if type.to_s.start_with?('_')
        values =
          values.reverse_merge(SEARCH_MENU_DEFAULT).tap do |v|
            v[:label_visible] = true if v[:label_visible].nil?
            vis               = v[:label_visible]
            v[:label]         = v[:label].gsub(/ /, '&nbsp;').html_safe if vis
            v[:menu_format]   = v[:menu_format]&.to_sym
            v[:url_parameter] = v[:url_parameter]&.to_sym || type
            v[:values].map!(&:to_s) if v[:values]
          end
        [type, values]
      }.compact.to_h.deep_freeze

    # If a :sort parameter value ends with this, it indicates that the sort
    # should be performed in reverse order.
    #
    # @type [String]
    #
    REVERSE_SORT = '_rev'

    # Format a menu label.
    #
    # @param [Symbol] menu_name
    # @param [String] label           Original label text.
    # @param [Hash]   opt
    #
    # @option opt [Symbol] :fmt       One of:
    #
    #   nil         No formatting.
    #   :none       No formatting.
    #   :titleize   Format in "title case".
    #   :upcase     Format as all uppercase.
    #   :downcase   Format as all lowercase.
    #   Symbol      Other String method.
    #   (missing)   Default `#SEARCH_MENU[menu_name][:menu_format]`.
    #
    # @return [String]
    #
    def make_menu_label(menu_name, label, **opt)
      label  = label.to_s.squish
      format = opt[:fmt]
      format = SEARCH_MENU.dig(menu_name, :menu_format) unless opt.key?(:fmt)
      format = DEF_MENU_LABEL_FMT if true?(format)
      format = nil                if format == :none
      format ? label.send(format) : label
    end

    # Generate an array of label/value pairs to be used with #select_tag.
    #
    # @param [Symbol]                            menu_name
    # @param [Array<Class,String,Numeric,Array>] entries
    # @param [Hash]                              opt
    #
    # @option opt [Symbol]  :fmt          @see #make_menu_label
    # @option opt [Boolean] :reversible   If *true*, include reverse entries.
    #
    # @return [Array<Array<(String,String)>>]
    #
    def make_menu(menu_name, *entries, **opt)
      reverse = opt[:reversible].present?
      entries = entries.flat_map { |v| v.respond_to?(:values) ? v.values : v }
      entries.compact!
      entries.uniq!
      entries.flat_map do |v|
        label = make_menu_label(menu_name, v, **opt)
        rev   = reverse && (label != 'Relevance')
        pairs = []
        pairs << [label, v]
        pairs << ["#{label} (rev)", "#{v}#{REVERSE_SORT}"] if rev
        pairs
      end
    end

  end

  include ClassMethods
  extend  ClassMethods

  # ===========================================================================

  # Sort menus for each controller type that should have a sort menu.
  #
  # @type [Hash{Symbol=>Array}]
  #
  SORT_MENU_MAP = {
    member:       MemberSortOrder,
    periodical:   PeriodicalSortOrder,
    reading_list: MyReadingListSortOrder,
    title:        TitleSortOrder,
  }.transform_values { |enumeration|
    make_menu(:sort, enumeration, reversible: true)
  }.deep_freeze

  # ===========================================================================

  # The generic page size menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  SIZE_MENU = make_menu(:size, SEARCH_MENU.dig(:size, :values)).deep_freeze

  # Page size menus for each controller type that should have a page size menu.
  #
  # @type [Hash{Symbol=>Array}]
  #
  SIZE_MENU_MAP = {
    category:     SIZE_MENU,
    member:       SIZE_MENU,
    periodical:   SIZE_MENU,
    reading_list: SIZE_MENU,
    title:        SIZE_MENU,
  }.freeze

  # ===========================================================================

  # Entries that should be at the top of #LANGUAGE_MENU.
  #
  # @type [Hash{Symbol=>String}]
  #
  PRIMARY_LANGUAGES = {
    eng: 'English',
    spa: 'Spanish',
  }.freeze

  # Patterns matching languages that should not be included in #LANGUAGE_MENU.
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
  LANGUAGE_MENU =
    ISO_639::ISO_639_2.map { |entry|
      label =
        entry.english_name.sub(/;.*$/, '').sub(/^Greek, Modern.*$/, 'Greek')
      bogus = BOGUS_LANGUAGE.any? { |pattern| label =~ pattern }
      [label, entry.alpha3_bibliographic] unless bogus
    }.compact
      .sort
      .unshift(*PRIMARY_LANGUAGES.map { |code, name| [name.to_s, code.to_s ] })
      .uniq
      .deep_freeze

  # Language menus for each controller type that should have a language menu.
  #
  # @type [Hash{Symbol=>Array}]
  #
  LANGUAGE_MENU_MAP =
    %i[periodical title].map { |type| [type, LANGUAGE_MENU] }.to_h.freeze

  # ===========================================================================

  COUNTRY_MENU =
    make_menu(:country, 'US', 'et al.').deep_freeze

  # @type [Hash{Symbol=>Array}]
  COUNTRY_MENU_MAP =
    %i[periodical title].map { |type| [type, COUNTRY_MENU] }.to_h.freeze

  # ===========================================================================

  CATEGORY_MENU =
    make_menu(:category, 'Animals', 'Art and Architecture', 'etc.').deep_freeze

  # @type [Hash{Symbol=>Array}]
  CATEGORY_MENU_MAP =
    %i[periodical title].map { |type| [type, CATEGORY_MENU] }.to_h.freeze

  # ===========================================================================

  # noinspection RubyYardParamTypeMatch
  FORMAT_MENU =
    I18n.t('emma.format').map { |value, label|
      [label.to_s, value.to_s]
    }.deep_freeze

  # noinspection RubyYardParamTypeMatch
  PERIODICAL_FORMAT_MENU =
    I18n.t('emma.periodical_format').map { |value, label|
      [label.to_s, value.to_s]
    }.deep_freeze

  # @type [Hash{Symbol=>Array}]
  FORMAT_MENU_MAP = {
    title:      FORMAT_MENU,
    periodical: PERIODICAL_FORMAT_MENU,
  }.freeze

  # ===========================================================================

  # noinspection RubyYardParamTypeMatch
  NARRATOR_MENU =
    make_menu(:narrator, NarratorType).deep_freeze

  # @type [Hash{Symbol=>Array}]
  NARRATOR_MENU_MAP =
    %i[periodical title].map { |type| [type, NARRATOR_MENU] }.to_h.freeze

  # ===========================================================================

  # noinspection RubyYardParamTypeMatch
  BRAILLE_MENU =
    make_menu(:braille, BrailleType).deep_freeze

  # @type [Hash{Symbol=>Array}]
  BRAILLE_MENU_MAP =
    %i[periodical title].map { |type| [type, BRAILLE_MENU] }.to_h.freeze

  # ===========================================================================

  # noinspection RubyYardParamTypeMatch
  WARNINGS_MENU =
    make_menu(:warnings, ContentWarning).deep_freeze

  # @type [Hash{Symbol=>Array}]
  WARNINGS_MENU_MAP =
    %i[periodical title].map { |type| [type, WARNINGS_MENU] }.to_h.freeze

  # ===========================================================================

  # noinspection RubyYardParamTypeMatch
  CONTENT_TYPE_MENU =
    make_menu(:content_type, TitleContentType).deep_freeze

  # @type [Hash{Symbol=>Array}]
  CONTENT_TYPE_MENU_MAP =
    %i[periodical title].map { |type| [type, CONTENT_TYPE_MENU] }.to_h.freeze

  # ===========================================================================

  # SEARCH_MENU_MAP
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_MENU_MAP = {
    braille:      BRAILLE_MENU_MAP,
    category:     CATEGORY_MENU_MAP,
    content_type: CONTENT_TYPE_MENU_MAP,
    country:      COUNTRY_MENU_MAP,
    format:       FORMAT_MENU_MAP,
    language:     LANGUAGE_MENU_MAP,
    narrator:     NARRATOR_MENU_MAP,
    size:         SIZE_MENU_MAP,
    sort:         SORT_MENU_MAP,
    warnings:     WARNINGS_MENU_MAP,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the search controls.
  #
  # @param [Hash, nil] p              Default: `#request_parameters`.
  #
  def show_search_controls?(p = nil)
    (p || request_parameters)[:action] == 'index'
  end

  # One or more rows of controls.
  #
  # @param [String, Symbol, nil]  type
  # @param [Hash]                 opt     Passed to #content_tag except for:
  #
  # @option opt [String, Symbol] :type    Default: `#search_type`.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # @see en.emma.search_controls
  #
  def search_controls(type = nil, **opt)
    opt, html_opt = partition_options(opt, :type)
    type = search_type(type || opt[:type])
    rows = i18n_lookup(type, 'search_controls.layout') || [[]]
    max_column = rows.map(&:size).max
    row = 0
    rows.map! do |menus|
      row += 1
      col  = 0
      menus.map { |name|
        col += 1
        method = name.to_s.end_with?('_menu') ? name : "#{name}_menu".to_sym
        if respond_to?(method, true)
          send(method, type: type, row: row, col: col)
        else
          name = name.to_s.delete_suffix('_menu').to_sym
          menu_container(name, type: type, row: row, col: col)
        end
      }.compact.tap { |columns|
        row -= 1 if columns.blank?
      }.presence
    end
    rows.compact!
    return if rows.blank?
    prepend_css_classes!(html_opt, 'search-controls', "columns-#{max_column}")
    content_tag(:div, safe_join(rows, "\n"), html_opt)
  end

  # A control for toggling the visibility of advanced search controls.
  #
  # @param [String, Symbol, nil] type
  # @param [String, nil]         label
  # @param [Hash]                opt    Passed to #button_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def advanced_search_button(type = nil, label = nil, **opt)
    type  ||= search_type
    label ||= i18n_lookup(type, 'search_bar.advanced.label')
    opt = prepend_css_classes(opt, 'advanced-search-toggle')
    opt[:type] ||= 'button'
    button_tag(label, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Perform a search specifying a collation order for the results.
  #
  # @param [String, nil] selected     Default: `#params[id]`.
  # @param [Hash]        opt          Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                     If menu is not available in this context.
  #
  # @see #SORT_MENU_MAP
  # @see ParamsConcern#resolve_sort
  #
  # == Implementation Notes
  # This method produces a URL parameter (:sort) which is translated into the
  # appropriate pair of :sortOrder and :direction parameters by #resolve_sort.
  #
  def sort_menu(selected = nil, **opt)
    menu_name = :sort
    p = request_parameters
    selected ||= (rp = request_parameters)[:sortOrder]
    selected ||= rp[SEARCH_MENU.dig(menu_name, :url_parameter)]
    selected &&= reverse_sort(selected) if p[:direction] == 'desc'
    menu_container(menu_name, selected, **opt)
  end

  # Perform a search specifying a results page size.
  #
  # @param [String, nil] selected     Default: `#params[id]`.
  # @param [Hash]        opt          Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                     If menu is not available in this context.
  #
  # @see #SIZE_MENU_MAP
  #
  def size_menu(selected = nil, **opt)
    menu_name = :size
    selected ||= request_parameters[SEARCH_MENU.dig(menu_name, :url_parameter)]
    selected ||= (page_size if respond_to?(:page_size))
    selected &&= selected.to_i
    menu_container(menu_name, selected, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A menu control preceded by a menu label (if provided).
  #
  # @param [Symbol]      menu_name
  # @param [String, nil] selected     Passed to #menu_control.
  # @param [Hash]        opt          Passed to #menu_control except for:
  #
  # @option opt [String]  :label      If missing, no label is included.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If menu is not available for *type*.
  #
  def menu_container(menu_name, selected = nil, **opt)
    label_opt, opt = partition_options(opt, :label)
    menu = menu_control(menu_name, selected, **opt)
    menu_label(menu_name, **opt.merge(label_opt)) + menu if menu
  end

  # A dropdown menu element.
  #
  # If *selected* is not specified `#SEARCH_MENU[menu_name][:url_parameter]` is
  # used to extract a value from `#request_parameters`.
  #
  # If no option is currently selected, an initial "null" selection is
  # prepended.
  #
  # @param [Symbol]      menu_name
  # @param [String, nil] selected
  # @param [Hash]        opt          Passed to #search_form except for:
  #
  # @option opt [String, Symbol] :type
  # @option opt [Integer]        :row
  # @option opt [Integer]        :col
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                     If menu is not available for *type*.
  #
  def menu_control(menu_name, selected = nil, **opt)
    local, opt = partition_options(opt, :type, :row, :col)
    type      = search_type(local[:type])
    menu      = SEARCH_MENU_MAP.dig(menu_name, type) or return
    url_param = SEARCH_MENU.dig(menu_name, :url_parameter)
    default   = SEARCH_MENU.dig(menu_name, :default)
    any_value = ''
    row       = local[:row].to_i
    col       = local[:col].to_i

    selected ||= request_parameters[url_param] || default || any_value
    if (selected = selected.to_s).blank?
      selected = any_value
    elsif menu.none? { |_, value| value == selected }
      # Insert a new entry if the selection value is not already in the menu.
      label = make_menu_label(menu_name, selected)
      menu += [[label, selected]]
      menu.sort_by! { |label, value| value.to_i.zero? ? label : value.to_i }
    end

    # Prepend a placeholder if not present.
    if default.blank? && menu.none? { |_, value| value == any_value }
      any_label = SEARCH_MENU.dig(menu_name, :placeholder) || '(select)'
      menu = [[any_label, any_value]] + menu
    end

    prepend_css_classes!(opt, 'menu-control', "row#{row}", "col#{col}")
    search_form(url_param, type, **opt) do
      option_tags = options_for_select(menu, selected)
      select_tag(url_param, option_tags, onchange: 'this.form.submit();')
    end
  end

  # A label associated with a dropdown menu element.
  #
  # @param [Symbol]      menu_name
  # @param [String, nil] label
  # @param [Hash]        opt          Passed to #label_tag except for:
  #
  # @option opt [String, Symbol] :type
  # @option opt [String]         :label
  # @option opt [Integer]        :row
  # @option opt [Integer]        :col
  #
  # @return [ActiveSupport::SafeBuffer]   Empty if no label was present.
  #
  def menu_label(menu_name, label = nil, **opt)
    local, html_opt = partition_options(opt, :type, :label, :row, :col)
    label ||= local[:label] || SEARCH_MENU.dig(menu_name, :label)
    return ''.html_safe if label.blank?
    url_param = SEARCH_MENU.dig(menu_name, :url_parameter)
    row = local[:row].to_i
    col = local[:col].to_i
    classes = %W(menu-label row#{row} col#{col})
    if !SEARCH_MENU.dig(menu_name, :label_visible)
      classes << 'sr-only'
    elsif !label.html_safe?
      label = ERB::Util.h(label).gsub(/ /, '&nbsp;').html_safe
    end
    prepend_css_classes!(html_opt, classes)
    label_tag(url_param, label, **html_opt)
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

end

__loading_end(__FILE__)
