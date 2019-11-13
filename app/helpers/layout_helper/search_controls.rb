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

    include GenericHelper

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The names and properties of all of the search control menus and default
    # values.
    #
    # @type [Hash]
    #
    # noinspection RailsI18nInspection
    SEARCH_CONTROLS = I18n.t('emma.search_controls')

    # The value 'emma.search_controls._default' contains each of the properties
    # that can be expressed for a menu.  If a property there has a non-nil
    # value, then that value is used as the default for that property.
    #
    # @type [Hash]
    #
    SEARCH_MENU_DEFAULT =
      SEARCH_CONTROLS[:_default].reject { |_, v| v.nil? }.deep_freeze

    # Properties for the "filter reset" button.
    #
    # @type [Hash]
    #
    # @see #reset_menu
    #
    SEARCH_RESET =
      SEARCH_CONTROLS[:_reset].reverse_merge(SEARCH_MENU_DEFAULT).deep_freeze

    # The names and properties of all of the search control menus.
    #
    # @type [Hash]
    #
    # noinspection RailsI18nInspection
    SEARCH_MENU =
      SEARCH_CONTROLS.map { |type, values|
        next if type.to_s.start_with?('_')
        values =
          values.reverse_merge(SEARCH_MENU_DEFAULT).tap do |v|
            v[:label_visible] = true if v[:label_visible].nil?
            v[:label]         = non_breaking(v[:label]) if v[:label_visible]
            v[:menu_format]   = v[:menu_format]&.to_sym
            v[:url_parameter] = v[:url_parameter]&.to_sym || type
            v[:values].map!(&:to_s) if v[:values]
            if (reverse = v[:reverse])
              reverse[:suffix] &&= reverse[:suffix].sub(/^([^_])/, '_\1')
              reverse[:except] &&= Array.wrap(reverse[:except]).map(&:to_sym)
            end
          end
        [type, values]
      }.compact.to_h.deep_freeze

    # URL parameters for all search control menus.
    #
    # @type [Array<Symbol>]
    #
    SEARCH_PARAMETERS =
      SEARCH_MENU.values.map { |v| v[:url_parameter] }.uniq.freeze

    # If a :sort parameter value ends with this, it indicates that the sort
    # should be performed in reverse order.
    #
    # @type [String]
    #
    REVERSE_SORT_SUFFIX = SEARCH_MENU.dig(:sort, :reverse, :suffix).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Generate an array of label/value pairs to be used with #select_tag.
    #
    # @param [Symbol]                            menu_name
    # @param [Array<Class,String,Numeric,Array>] entries
    # @param [Hash]                              opt
    #
    # @option opt [Symbol]  :fmt          @see #make_menu_label
    #
    # @return [Array<Array<(String,String)>>]
    #
    def make_menu(menu_name, *entries, **opt)
      reverse = SEARCH_MENU.dig(menu_name, :reverse)
      entries = entries.flat_map { |v| v.respond_to?(:values) ? v.values : v }
      entries.compact!
      entries.uniq!
      entries.flat_map do |value|
        [].tap do |pairs|
          label = make_menu_label(menu_name, value, **opt)
          pairs << [label, value]
          if reverse && !reverse[:except].include?(value)
            label = sprintf(reverse[:label], sort: label)
            value = descending_sort(value, reverse[:suffix])
            pairs << [label, value]
          end
        end
      end
    end

    # Format a menu label.
    #
    # @param [Symbol] menu_name
    # @param [String] label           Original label text.
    # @param [Hash]   opt
    #
    # @option opt [Symbol] :fmt       One of:
    #
    #   *nil*       No formatting.
    #   *false*     No formatting.
    #   :none       No formatting.
    #   :titleize   Format in "title case".
    #   :upcase     Format as all uppercase.
    #   :downcase   Format as all lowercase.
    #   Symbol      Other String method.
    #   *true*      Default `#SEARCH_MENU[menu_name][:menu_format]`.
    #   (missing)   Default `#SEARCH_MENU[menu_name][:menu_format]`.
    #
    # @return [String]
    #
    def make_menu_label(menu_name, label, **opt)
      label  = label.to_s.squish
      format = opt.key?(:fmt)
      # noinspection RubyCaseWithoutElseBlockInspection
      format &&=
        case opt[:fmt]
          when nil, false then :none
          when Symbol     then opt[:fmt]
        end
      format ||= SEARCH_MENU.dig(menu_name, :menu_format)
      format = nil if format == :none
      format ? label.send(format) : label
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the :sort is a reversed (descending) sort.
    #
    # @param [String] value           A :sort key.
    # @param [String] suffix          Default: #REVERSE_SORT_SUFFIX
    #
    def is_reverse?(value, suffix = nil)
      suffix ||= REVERSE_SORT_SUFFIX
      value.to_s.end_with?(suffix)
    end

    # Change :sort value to indicate a normal (ascending) sort.
    #
    # @param [String] value           Base :sort key.
    # @param [String] suffix          Default: #REVERSE_SORT_SUFFIX
    #
    # @return [String]
    # @return [nil]                   If *value* is blank.
    #
    def ascending_sort(value, suffix = nil)
      return if (value = value.to_s).blank?
      suffix ||= REVERSE_SORT_SUFFIX
      value.delete_suffix(suffix)
    end

    # Change :sort value to indicate a reversed (descending) sort.
    #
    # @param [String] value           Base :sort key.
    # @param [String] suffix          Default: #REVERSE_SORT_SUFFIX
    #
    # @return [String]
    # @return [nil]                   If *value* is blank.
    #
    def descending_sort(value, suffix = nil)
      return if (value = value.to_s).blank?
      suffix ||= REVERSE_SORT_SUFFIX
      value.end_with?(suffix) ? value : "#{value}#{suffix}"
    end

  end

  include ClassMethods
  extend  ClassMethods

  # ===========================================================================

  # Sort menus for each controller type that should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
  # noinspection RubyYardParamTypeMatch
  SORT_MENU_MAP = {
    member:       make_menu(:sort, MemberSortOrder),
    periodical:   make_menu(:sort, PeriodicalSortOrder),
    reading_list: make_menu(:sort, MyReadingListSortOrder),
    title:        make_menu(:sort, TitleSortOrder),
  }.deep_freeze

  # ===========================================================================

  # The generic page size menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  SIZE_MENU = make_menu(:size, SEARCH_MENU.dig(:size, :values)).deep_freeze

  # Page size menus for each controller type that should have one.
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

  # The generic language menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  # noinspection RailsI18nInspection
  LANGUAGE_MENU = (
    primary = I18n.t('emma.language.primary', default: []).map(&:to_s)
    entries = I18n.t('emma.language.list').map { |code, lbl| [lbl, code.to_s] }
    entries.partition { |_, code| primary.include?(code) }
  ).flatten(1).deep_freeze

  # Language limiter menus for each controller type that should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
  LANGUAGE_MENU_MAP =
    %i[periodical title].map { |type| [type, LANGUAGE_MENU] }.to_h.freeze

  # ===========================================================================

  # The generic country menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  COUNTRY_MENU =
    make_menu(:country, 'US', 'et al.').deep_freeze

  # Country limiter menus for each controller type that should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
  COUNTRY_MENU_MAP =
    %i[periodical title].map { |type| [type, COUNTRY_MENU] }.to_h.freeze

  # ===========================================================================

  # @type [Hash]
  # noinspection RailsI18nInspection
  CATEGORY_ENTRIES = I18n.t('emma.categories').deep_freeze

  # The generic category menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  CATEGORY_MENU = CATEGORY_ENTRIES.map { |_, v| [v, v] }.deep_freeze

  # Category limiter menus for each controller type that should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
  CATEGORY_MENU_MAP =
    %i[periodical title].map { |type| [type, CATEGORY_MENU] }.to_h.freeze

  # ===========================================================================

  # The generic catalog artifact format menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  # noinspection RailsI18nInspection
  FORMAT_MENU =
    I18n.t('emma.format').map { |value, label|
      [label.to_s, value.to_s]
    }.deep_freeze

  # The generic periodical edition artifact format menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  # noinspection RailsI18nInspection
  PERIODICAL_FORMAT_MENU =
    I18n.t('emma.periodical_format').map { |value, label|
      [label.to_s, value.to_s]
    }.deep_freeze

  # Format limiter menus for each controller type that should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
  FORMAT_MENU_MAP = {
    title:      FORMAT_MENU,
    periodical: PERIODICAL_FORMAT_MENU,
  }.freeze

  # ===========================================================================

  # The generic narrator menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  # noinspection RubyYardParamTypeMatch
  NARRATOR_MENU =
    make_menu(:narrator, NarratorType).deep_freeze

  # Narrator limiter menus for each controller type that should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
  NARRATOR_MENU_MAP =
    %i[periodical title].map { |type| [type, NARRATOR_MENU] }.to_h.freeze

  # ===========================================================================

  # The generic braille type menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  # noinspection RubyYardParamTypeMatch
  BRAILLE_MENU =
    make_menu(:braille, BrailleType).deep_freeze

  # Braille type limiter menus for each controller type that should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
  BRAILLE_MENU_MAP =
    %i[periodical title].map { |type| [type, BRAILLE_MENU] }.to_h.freeze

  # ===========================================================================

  # The generic excluded-content-warnings menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  # noinspection RubyYardParamTypeMatch
  WARNINGS_EXC_MENU =
    make_menu(:warnings_exc, ContentWarning).deep_freeze

  # Excluded-content-warnings limiter menus for each controller type that
  # should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
  WARNINGS_EXC_MENU_MAP =
    %i[periodical title].map { |type| [type, WARNINGS_EXC_MENU] }.to_h.freeze

  # ===========================================================================

  # The generic included-content-warnings menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  # noinspection RubyYardParamTypeMatch
  WARNINGS_INC_MENU =
    make_menu(:warnings_inc, ContentWarning).deep_freeze

  # Included-content-warnings limiter menus for each controller type that
  # should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
  WARNINGS_INC_MENU_MAP =
    %i[periodical title].map { |type| [type, WARNINGS_INC_MENU] }.to_h.freeze

  # ===========================================================================

  # The generic content type menu.
  #
  # @type [Array<Array<(String,String)>>]
  #
  # noinspection RubyYardParamTypeMatch
  CONTENT_TYPE_MENU =
    make_menu(:content_type, TitleContentType).deep_freeze

  # Content type limiter menus for each controller type that should have one.
  #
  # @type [Hash{Symbol=>Array}]
  #
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
    warnings_exc: WARNINGS_EXC_MENU_MAP,
    warnings_inc: WARNINGS_INC_MENU_MAP,
  }.freeze

  # ===========================================================================

  # Label for button to open advanced search controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  ADV_SEARCH_OPENER_LABEL =
    non_breaking(
      I18n.t('emma.search_bar.advanced.label')
    ).html_safe.freeze

  # Tooltip for button to open advanced search controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  ADV_SEARCH_OPENER_TIP =
    I18n.t('emma.search_bar.advanced.tooltip').freeze

  # Label for button to close advanced search controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  ADV_SEARCH_CLOSER_LABEL =
    non_breaking(
      I18n.t('emma.search_bar.advanced.open.label')
    ).html_safe.freeze

  # Tooltip for button to close advanced search controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  ADV_SEARCH_CLOSER_TIP =
    I18n.t('emma.search_bar.advanced.open.tooltip').freeze

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
    opt[:type]    = search_type(type || opt[:type])
    grid_rows     = i18n_lookup(opt[:type], 'search_controls.layout') || [[]]
    opt[:row_max] = grid_rows.size
    opt[:col_max] = max_columns = grid_rows.map(&:size).max
    opt[:row]     = 0
    grid_rows.map! do |menus|
      opt[:row] += 1
      opt[:col]  = 0
      menus.map { |name|
        opt[:col] += 1
        name   = name.to_s.delete_suffix('_menu')
        method = "#{name}_menu".to_sym
        if respond_to?(method, true)
          send(method, **opt)
        else
          menu_container(name, **opt)
        end
      }.compact.tap { |columns|
        opt[:row] -= 1 if columns.blank?
      }.presence
    end
    grid_rows.compact!
    return if grid_rows.blank?
    prepend_css_classes!(html_opt, 'search-controls', "columns-#{max_columns}")
    content_tag(:div, safe_join(grid_rows, "\n"), html_opt)
  end

  # A control for toggling the visibility of advanced search controls.
  #
  # @param [String, nil]         label
  # @param [Hash]                opt    Passed to #button_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def advanced_search_button(label = nil, **opt)
    opt = opt.reverse_merge(type: 'button', title: ADV_SEARCH_OPENER_TIP)
    prepend_css_classes!(opt, 'advanced-search-toggle')
    button_tag(**opt) { label ? non_breaking(label) : ADV_SEARCH_OPENER_LABEL }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Options consumed by internal methods which should not be passed on along to
  # the methods which generate HTML elements.
  #
  # @type [Array<Symbol>]
  #
  MENU_OPTS = %i[type label row col row_max col_max].freeze

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
    menu_name  = :sort
    params     = request_parameters
    selected ||= params[:sortOrder]
    selected ||= params[SEARCH_MENU.dig(menu_name, :url_parameter)]
    selected &&= descending_sort(selected) if params[:direction] == 'desc'
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
    menu_name  = :size
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
  # @param [String, Symbol] menu_name
  # @param [String, nil]    selected    Passed to #menu_control.
  # @param [Hash]           opt         Passed to #menu_control except for:
  #
  # @option opt [String] :label         If missing, no label is included.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If menu is not available for *type*.
  #
  def menu_container(menu_name, selected = nil, **opt)
    label_opt, control_opt = partition_options(opt, :label)
    menu_name = menu_name.to_sym
    control_opt[:title] ||= SEARCH_MENU.dig(menu_name, :tooltip)
    menu  = menu_control(menu_name, selected, **control_opt) or return
    label = menu_label(menu_name, **control_opt.merge(label_opt))
    label + menu
  end

  # A dropdown menu element.
  #
  # If *selected* is not specified `#SEARCH_MENU[menu_name][:url_parameter]` is
  # used to extract a value from `#request_parameters`.
  #
  # If no option is currently selected, an initial "null" selection is
  # prepended.
  #
  # @param [String, Symbol] menu_name
  # @param [String, nil]    selected
  # @param [Hash]           opt           Passed to #search_form except for:
  #
  # @option opt [String, Symbol] :type    Validated and passed to #search_form.
  # @option opt [String]         :label   (unused)
  # @option opt [Integer]        :row     Grid row (wide screen).
  # @option opt [Integer]        :col     Grid column (wide screen).
  # @option opt [Integer]        :row_max Bottom grid row (wide screen).
  # @option opt [Integer]        :col_max Rightmost grid column (wide screen).
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If menu is not available for *type*.
  #
  def menu_control(menu_name, selected = nil, **opt)
    opt, html_opt = partition_options(opt, *MENU_OPTS)
    menu_name = menu_name.to_sym
    type      = search_type(opt[:type])
    menu      = SEARCH_MENU_MAP.dig(menu_name, type) or return
    url_param = SEARCH_MENU.dig(menu_name, :url_parameter)
    default   = SEARCH_MENU.dig(menu_name, :default)
    any_value = ''

    selected ||= request_parameters[url_param] || default || any_value
    if (selected = selected.to_s).blank?
      selected = any_value
    elsif menu.none? { |_, value| value == selected }
      # Insert a new entry if the selection value is not already in the menu.
      sort  = entries_sorted?(menu)
      # noinspection RubyYardParamTypeMatch
      label = make_menu_label(menu_name, selected)
      menu += [[label, selected]]
      sort_entries!(menu) if sort
    end

    # Prepend a placeholder if not present.
    if default.blank? && menu.none? { |_, value| value == any_value }
      any_label = SEARCH_MENU.dig(menu_name, :placeholder) || '(select)'
      menu = [[any_label, any_value]] + menu
    end

    # Add CSS classes which indicate the position of the control.
    prepend_grid_cell_classes!(html_opt, 'menu-control', **opt)
    search_form(url_param, type, **html_opt) do
      option_tags = options_for_select(menu, selected)
      select_tag(url_param, option_tags, onchange: 'this.form.submit();')
    end
  end

  # A label associated with a dropdown menu element.
  #
  # @param [String, Symbol] menu_name
  # @param [String, nil]    label
  # @param [Hash]           opt           Passed to #label_tag except for:
  #
  # @option opt [String, Symbol] :type    (unused)
  # @option opt [String]         :label   Label text if *label* is not given.
  # @option opt [Integer]        :row     Grid row (wide screen).
  # @option opt [Integer]        :col     Grid column (wide screen).
  # @option opt [Integer]        :row_max Bottom grid row (wide screen).
  # @option opt [Integer]        :col_max Rightmost grid column (wide screen).
  #
  # @return [ActiveSupport::SafeBuffer]   Empty if no label was present.
  #
  def menu_label(menu_name, label = nil, **opt)
    opt, html_opt = partition_options(opt, *MENU_OPTS)
    menu_name = menu_name.to_sym
    label   ||= opt[:label] || SEARCH_MENU.dig(menu_name, :label)
    return ''.html_safe if label.blank?
    url_param = SEARCH_MENU.dig(menu_name, :url_parameter)
    visible   = SEARCH_MENU.dig(menu_name, :label_visible)
    label     = non_breaking(label) if visible
    opt[:sr_only] = !visible
    opt.delete(:col_max) # Labels shouldn't have the 'col-last' CSS class.
    prepend_grid_cell_classes!(html_opt, 'menu-label', **opt)
    label_tag(url_param, label, **html_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # URL parameters for #reset_menu.
  #
  # @type [Array<Symbol>]
  #
  RESET_PARAMETERS = (SEARCH_PARAMETERS - %i[sort limit]).freeze

  # The controls for resetting filter menu selections to their default state.
  #
  # @param [String, Hash, nil] url    Default from #request_parameters.
  # @param [Hash]              opt    Passed to #menu_spacer and #reset_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def reset_menu(url = nil, **opt)
    menu_spacer(**opt) + reset_button(url, **opt)
  end

  # A button to reset all filter menu selections to their default state.
  #
  # @param [String, Hash, nil] url    Default from #request_parameters.
  # @param [Hash]              opt    Passed to #link_to except for:
  #
  # @option opt [String]  :class      CSS classes for both spacer and button.
  # @option opt [String]  :label      Button label.
  # @option opt [Integer] :row        Grid row (wide screen).
  # @option opt [Integer] :col        Grid column (wide screen).
  # @option opt [Integer] :row_max    Bottom grid row (wide screen).
  # @option opt [Integer] :col_max    Rightmost grid column (wide screen).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #SEARCH_RESET
  # @see #RESET_PARAMETERS
  #
  def reset_button(url = nil, **opt)
    opt, html_opt = partition_options(opt, :class, *MENU_OPTS)
    label = opt[:label] || SEARCH_RESET[:label]
    label = non_breaking(label)
    url ||= request_parameters.except(*RESET_PARAMETERS)
    url   = url_for(url) if url.is_a?(Hash)
    prepend_grid_cell_classes!(html_opt, 'menu-button', **opt)
    html_opt[:title] ||= SEARCH_RESET[:tooltip]
    link_to(label, url, **html_opt)
  end

  # A button to reset all filter menu selections to their default state.
  #
  # @param [Hash] opt                 Passed to #content_tag except for:
  #
  # @option opt [String]  :class      CSS classes for both spacer and button.
  # @option opt [Integer] :row        Grid row (wide screen).
  # @option opt [Integer] :col        Grid column (wide screen).
  # @option opt [Integer] :row_max    Bottom grid row (wide screen).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def menu_spacer(**opt)
    opt, html_opt = partition_options(opt, :class, *MENU_OPTS)
    opt.delete(:col_max) # Spacers shouldn't have the 'col-last' CSS class.
    prepend_grid_cell_classes!(html_opt, 'menu-spacer', **opt)
    content_tag(:div, '&nbsp;'.html_safe, **html_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]  html_opt
  # @param [Array] classes
  # @param [Hash]  opt                Passed to #grid_cell_classes.
  #
  # @return [Hash]                    The modified *html_opt* hash.
  #
  def prepend_grid_cell_classes!(html_opt, *classes, **opt)
    classes = grid_cell_classes(*classes, **opt)
    prepend_css_classes!(html_opt, *classes)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Array] classes
  # @param [Hash]  opt
  #
  # @option opt [String]  :class
  # @option opt [Integer] :row        Grid row (wide screen).
  # @option opt [Integer] :col        Grid column (wide screen).
  # @option opt [Integer] :row_max    Bottom grid row (wide screen).
  # @option opt [Integer] :col_max    Rightmost grid column (wide screen).
  # @option opt [Boolean] :sr_only    If *true*, include 'sr-only' CSS class.
  #
  # @return [Array<String>]
  #
  def grid_cell_classes(*classes, **opt)
    row = positive(opt[:row])
    col = positive(opt[:col])
    classes += Array.wrap(opt[:class])
    classes << "row-#{row}" if row
    classes << "col-#{col}" if col
    classes << 'row-first'  if row == 1
    classes << 'col-first'  if col == 1
    classes << 'row-last'   if row == opt[:row_max].to_i
    classes << 'col-last'   if col == opt[:col_max].to_i
    classes << 'sr-only'    if opt[:sr_only]
    classes
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Indicate whether the menu is already sorted.
  #
  # @param [Array<Array<(String,*)>>] menu
  #
  def entries_sorted?(menu)
    sort_entries(menu) == menu
  end

  # Return a sorted copy of the menu.
  #
  # @param [Array<Array<(String,*)>>] menu
  #
  # @return [Array<Array<(String,*)>>]
  #
  def sort_entries(menu)
    sort_entries!(menu.dup)
  end

  # Sort the menu by value if the value is a number or by the label otherwise.
  #
  # @param [Array<Array<(String,*)>>] menu
  #
  # @return [Array<Array<(String,*)>>]  The possibly-modified *menu*.
  #
  def sort_entries!(menu)
    menu.sort_by! { |label, value| value.to_i.zero? ? label : value.to_i }
  end

end

__loading_end(__FILE__)
