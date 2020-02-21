# app/helpers/layout_helper/search_controls.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'bs'
require 'search'

# LayoutHelper::SearchControls
#
module LayoutHelper::SearchControls

  include LayoutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods

    include Emma::Common

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
    SEARCH_MENU_DEFAULT = SEARCH_CONTROLS[:_default].compact.deep_freeze

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
    REVERSE_SORT_SUFFIX = SEARCH_MENU.dig(:sort, :reverse, :suffix)

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Generate an array of label/value pairs to be used with #select_tag.
    #
    # @overload make_menu(menu_name, *entries, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Array<String>] entries
    #   @param [Hash]          opt          Passed to #make_menu_label.
    #
    # @overload make_menu(menu_name, *entries, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Array<Symbol>] entries      Traversal of #SEARCH_MENU
    #   @param [Hash]          opt          Passed to #make_menu_label.
    #
    # @overload make_menu(menu_name, i18n_scope, **opt)
    #   @param [Symbol]        menu_name
    #   @param [String]        i18n_scope
    #   @param [Hash]          opt          Passed to #make_menu_label.
    #
    # @overload make_menu(menu_name, enum_class, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Class]         enum_class
    #   @param [Hash]          opt
    #
    # @overload make_menu(menu_name, menu_pairs, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Array<Array>]  menu_pairs
    #   @param [Hash]          opt          Passed to #make_menu_label.
    #
    # @option opt [Symbol] :fmt       @see #make_menu_label
    #
    # @return [Array<Array<(String,String)>>]
    #
    def make_menu(menu_name, *entries, **opt)
      first = entries.first
      if menu_name == :language
        hash    = I18n.t(first)
        entries = hash[:list].map { |code, label| [label, code.to_s] }
        if (p = hash[:primary]&.map(&:to_s)).present?
          entries = entries.partition { |_, code| p.include?(code) }.flatten(1)
        end
      elsif menu_name == :category
        entries = I18n.t(first).map { |_, label| [label, label] }
      elsif first.is_a?(Symbol)
        entries = SEARCH_MENU.dig(*entries).dup
      elsif entries.size > 1
        entries = entries.flatten(1)
      elsif first.is_a?(String)
        entries = I18n.t(first).map { |value, label| [label, value.to_s] }
      elsif first.respond_to?(:values)
        entries = first.values.dup
      end
      entries.compact!
      entries.uniq!
      entries.map! do |entry|
        if entry.is_a?(Array)
          entry
        else
          value = entry
          label = make_menu_label(menu_name, value, **opt)
          [label, value]
        end
      end
      if (reverse = SEARCH_MENU.dig(menu_name, :reverse)).blank?
        entries
      else
        except = Array.wrap(reverse[:except]).map(&:to_s)
        entries.flat_map do |entry|
          label, value = entry
          if except.include?(value)
            entry
          else
            label = sprintf(reverse[:label], sort: label)
            value = descending_sort(value, reverse[:suffix])
            [entry, [label, value]]
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
  # :section:
  # ===========================================================================

  public

  # Controllers configured to display search control menu(s).
  #
  # @type [Array<Symbol>]
  #
  # noinspection RailsI18nInspection
  SEARCH_MENU_CONTROLLERS =
    I18n.t('emma').map { |type, section|
      type if section.dig(:search_controls, :layout).present?
    }.compact.freeze

  # Generate menu content for items that are the same regardless of the context
  # in which they are presented.
  #
  # @type [Hash{Symbol=>Array}]
  #
  # @see #make_menu
  #
  GENERIC_MENU = {
    a11y_feature: A11yFeature,
    braille:      BrailleType,
    category:     'emma.categories',  # @see config/locales/en.yml
    content_type: TitleContentType,
    format:       nil,                # @see SEARCH_MENU_MAP
    language:     'emma.language',    # @see config/locales/en.yml
    narrator:     NarratorType,
    repository:   EmmaRepository,
    size:         %i[size values],    # @see #SEARCH_MENU
    sort:         nil,                # @see SEARCH_MENU_MAP
    warnings_exc: ContentWarning,
    warnings_inc: ContentWarning,
  }.map { |name, entries|
    entries &&= make_menu(name, *entries)
    [name, entries]
  }.to_h.deep_freeze

  # Menus for each controller.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_MENU_MAP =
    SEARCH_MENU_CONTROLLERS.map { |controller|
      menus =
        GENERIC_MENU.map { |menu_name, menu|
          # noinspection RubyCaseWithoutElseBlockInspection
          entries =
            case menu_name
              when :sort
                # noinspection RubyCaseWithoutElseBlockInspection
                case controller
                  when :member       then MemberSortOrder
                  when :periodical   then PeriodicalSortOrder
                  when :reading_list then MyReadingListSortOrder
                  when :title        then TitleSortOrder
                  when :search       then SearchSort
                end
              when :format
                # noinspection RubyCaseWithoutElseBlockInspection
                case controller
                  when :periodical      then 'emma.periodical_format'
                  when :title           then 'emma.book_format'
                  when :search, :upload then 'emma.format'
                end
            end
          menu = make_menu(menu_name, *entries) if entries
          [menu_name, menu] if menu
        }.compact.to_h
      [controller, menus]
    }.to_h.deep_freeze

  # ===========================================================================

  # Label for button to open advanced search controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  # noinspection RailsI18nInspection
  ADV_SEARCH_OPENER_LABEL =
    non_breaking(I18n.t('emma.search_bar.advanced.label')).html_safe.freeze

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
  # noinspection RailsI18nInspection
  ADV_SEARCH_CLOSER_LABEL =
    non_breaking(I18n.t('emma.search_bar.advanced.open.label')).html_safe.freeze

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
  # @param [String, Symbol] type      Default: `#search_type`.
  # @param [Hash]           opt       Passed to #content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # @see en.emma.search_controls
  #
  def search_controls(type: nil, **opt)
    type = search_type(type)
    grid_rows = i18n_lookup(type, 'search_controls.layout') || [[]]
    grid_opt  = { type: type, row: 0 }
    grid_opt[:row_max] = grid_rows.size
    grid_opt[:col_max] = max_columns = grid_rows.map(&:size).max
    grid_rows.map! do |menus|
      grid_opt[:row] += 1
      grid_opt[:col]  = 0
      menus.map { |name|
        grid_opt[:col] += 1
        name   = name.to_s.delete_suffix('_menu')
        method = "#{name}_menu".to_sym
        if respond_to?(method, true)
          send(method, **grid_opt)
        else
          menu_container(name, **grid_opt)
        end
      }.compact.tap { |columns|
        grid_opt[:row] -= 1 if columns.blank?
      }.presence
    end
    grid_rows.compact!
    return if grid_rows.blank?
    opt = prepend_css_classes(opt, 'search-controls', "columns-#{max_columns}")
    content_tag(:div, safe_join(grid_rows, "\n"), opt)
  end

  # A control for toggling the visibility of advanced search controls.
  #
  # @param [String, nil] label        Default: #ADV_SEARCH_OPENER_LABEL.
  # @param [Hash]        opt          Passed to #button_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def advanced_search_button(label: nil, **opt)
    opt = prepend_css_classes(opt, 'advanced-search-toggle')
    opt[:title] ||= ADV_SEARCH_OPENER_TIP
    opt[:type]  ||= 'button'
    button_tag(opt) { label ? non_breaking(label) : ADV_SEARCH_OPENER_LABEL }
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
  # @see HtmlHelper#GRID_OPTS
  #
  MENU_OPTS = [:type, :label, :selected, *GRID_OPTS].freeze

  # Perform a search specifying a collation order for the results.
  # (Default: `#params[:sortOrder]`.)
  #
  # @param [Hash] opt                 Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                     If menu is not available in this context.
  #
  # @see #SORT_MENU_MAP
  # @see #search_controls
  # @see ParamsConcern#resolve_sort
  #
  # == Implementation Notes
  # This method produces a URL parameter (:sort) which is translated into the
  # appropriate pair of :sortOrder and :direction parameters by #resolve_sort.
  #
  def sort_menu(**opt)
    menu_name = :sort
    params    = request_parameters
    direction = params[:direction]
    opt[:selected] ||= params[:sortOrder]
    opt[:selected] ||= params[SEARCH_MENU.dig(menu_name, :url_parameter)]
    opt[:selected] &&= descending_sort(opt[:selected]) if direction == 'desc'
    menu_container(menu_name, **opt)
  end

  # Perform a search specifying a results page size.  (Default: `#page_size`.)
  #
  # @param [Hash] opt                 Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                     If menu is not available in this context.
  #
  # @see #SIZE_MENU_MAP
  # @see #search_controls
  # @see PaginationHelper#page_size
  #
  def size_menu(**opt)
    menu_name = :size
    params    = request_parameters
    opt[:selected] ||= params[SEARCH_MENU.dig(menu_name, :url_parameter)]
    opt[:selected] ||= (page_size if respond_to?(:page_size))
    opt[:selected] &&= opt[:selected].to_i
    menu_container(menu_name, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A menu control preceded by a menu label (if provided).
  #
  # @param [String, Symbol] name        Menu name.
  # @param [Hash]           opt         Passed to #menu_control except for:
  #
  # @option opt [String] :label         If missing, no label is included.
  # @option opt [String] :selected      Passed to #menu_control.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If menu is not available for *type*.
  #
  def menu_container(name, **opt)
    local, opt = partition_options(opt, :label, :selected)
    name     = name.to_sym
    label    = local[:label]
    selected = local[:selected]
    opt[:title] ||= SEARCH_MENU.dig(name, :tooltip)
    menu  = menu_control(name, **opt.merge(selected: selected)) or return
    label = menu_label(name, **opt.merge(label: label))
    label << menu
  end

  # A dropdown menu element.
  #
  # If *selected* is not specified `#SEARCH_MENU[menu_name][:url_parameter]` is
  # used to extract a value from `#request_parameters`.
  #
  # If no option is currently selected, an initial "null" selection is
  # prepended.
  #
  # @param [String, Symbol] name    Menu name.
  # @param [Hash]           opt     Passed to #label_tag except for #MENU_OPTS:
  #
  # @option opt [String, Symbol] :type      Passed to #search_form.
  # @option opt [String]         :selected  Selected menu item.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If menu is not available for *type*.
  #
  # @see HtmlHelper#grid_cell_classes
  #
  def menu_control(name, **opt)
    opt, html_opt = partition_options(opt, *MENU_OPTS)
    name      = name.to_sym
    type      = search_type(opt[:type])
    menu      = SEARCH_MENU_MAP.dig(type, name) or return
    url_param = SEARCH_MENU.dig(name, :url_parameter)
    default   = SEARCH_MENU.dig(name, :default)
    any_value = ''

    selected   = opt[:selected]
    selected ||= request_parameters[url_param] || default || any_value
    if (selected = selected.to_s).blank?
      selected = any_value
    elsif menu.none? { |_, value| value == selected }
      # Insert a new entry if the selection value is not already in the menu.
      sort  = entries_sorted?(menu)
      # noinspection RubyYardParamTypeMatch
      label = make_menu_label(name, selected)
      menu += [[label, selected]]
      sort_entries!(menu) if sort
    end

    # Prepend a placeholder if not present.
    if default.blank? && menu.none? { |_, value| value == any_value }
      any_label = SEARCH_MENU.dig(name, :placeholder) || '(select)'
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
  # @param [String, Symbol] name    Menu name.
  # @param [Hash]           opt     Passed to #label_tag except for #MENU_OPTS:
  #
  # @option opt [String] :label     Label text override.
  #
  # @return [ActiveSupport::SafeBuffer]   Empty if no label was present.
  #
  # @see HtmlHelper#prepend_grid_cell_classes!
  #
  def menu_label(name, **opt)
    opt, html_opt = partition_options(opt, *MENU_OPTS)
    name  = name.to_sym
    label = opt[:label] || SEARCH_MENU.dig(name, :label)
    if label.blank?
      ''.html_safe
    else
      url_param = SEARCH_MENU.dig(name, :url_parameter)
      visible   = !html_opt.delete(:sr_only)
      visible &&= SEARCH_MENU.dig(name, :label_visible)
      if visible
        label = non_breaking(label)
      else
        opt[:sr_only] = true
      end
      opt.delete(:col_max) # Labels shouldn't have the 'col-last' CSS class.
      prepend_grid_cell_classes!(html_opt, 'menu-label', **opt)
      label_tag(url_param, label, html_opt)
    end
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
  # @param [Hash] opt                 Passed to #menu_spacer and #reset_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def reset_menu(**opt)
    opt = append_css_classes(opt, 'reset')
    menu_spacer(**opt) << reset_button(**opt)
  end

  # A button to reset all filter menu selections to their default state.
  #
  # @param [Hash] opt             Passed to #link_to except for #GRID_OPTS and:
  #
  # @option opt [String] :url     Default from #request_parameters.
  # @option opt [String] :class   CSS classes for both spacer and button.
  # @option opt [String] :label   Button label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #SEARCH_RESET
  # @see #RESET_PARAMETERS
  # @see HtmlHelper#grid_cell_classes
  #
  def reset_button(**opt)
    opt, html_opt = partition_options(opt, :class, *MENU_OPTS)
    label = opt[:label] || SEARCH_RESET[:label]
    label = non_breaking(label)
    url   = opt[:url] || request_parameters.except(*RESET_PARAMETERS)
    url   = url_for(url) if url.is_a?(Hash)
    prepend_grid_cell_classes!(html_opt, 'reset', 'menu-button', **opt)
    html_opt[:title] ||= SEARCH_RESET[:tooltip]
    link_to(label, url, **html_opt)
  end

  # A button to reset all filter menu selections to their default state.
  #
  # @param [Hash] opt         Passed to #content_tag except for #GRID_OPTS and:
  #
  # @option opt [String] :class       CSS classes for both spacer and button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see HtmlHelper#prepend_grid_cell_classes!
  #
  def menu_spacer(**opt)
    opt, html_opt = partition_options(opt, :class, *MENU_OPTS)
    opt.delete(:col_max) # Spacers shouldn't have the 'col-last' CSS class.
    prepend_grid_cell_classes!(html_opt, 'menu-spacer', **opt)
    content_tag(:div, '&nbsp;'.html_safe, html_opt)
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
