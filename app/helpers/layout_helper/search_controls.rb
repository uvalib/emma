# app/helpers/layout_helper/search_controls.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::SearchControls
#
module LayoutHelper::SearchControls

  include LayoutHelper::Common
  include SearchTermsHelper

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

    # Generate the fully-realized configurations for all search controls
    # associated with a given controller.
    #
    # @param [Symbol] controller
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def search_controls_configs(controller)
      configs = SEARCH_CONTROLS_CONFIG.deep_dup
      %W(generic #{controller}.generic #{controller}).each do |section|
        cfg = I18n.t("emma.#{section}.search_controls", default: nil)
        configs.deep_merge!(cfg) if cfg.present?
      end
      configs = {} unless configs.dig(:_self, :enabled)
      configs.map { |menu_name, config|
        next if menu_name.to_s.start_with?('_')
        unless menu_name == :layout
          config = search_menu_config(menu_name, config)
          values = config[:values]
          values = I18n.t(values)             if values.is_a?(String)
          values = EnumType.pairs_for(values) if values.is_a?(Symbol)
          values = values.pairs               if values.is_a?(EnumType)
          values = values.map(&:to_s)         if values.is_a?(Array)
          config[:values] = values
          config[:menu]   = make_menu(menu_name, config).presence
        end
        [menu_name, config]
      }.compact.to_h
    end

    # Get the search menu configuration for the current context.
    #
    # @param [Symbol, String] menu_name
    # @param [Hash, nil]      properties
    #
    # @return [Hash]
    #
    def search_menu_config(menu_name, properties)
      SEARCH_MENU_DEFAULT.deep_merge(properties).deep_dup.tap do |cfg|
        cfg[:label_visible] = !false?(cfg[:label_visible])
        cfg[:label]         = non_breaking(cfg[:label]) if cfg[:label_visible]
        cfg[:menu_format]   = cfg[:menu_format]&.to_sym
        cfg[:url_parameter] = (cfg[:url_parameter] || menu_name)&.to_sym
        if (reverse = cfg[:reverse])
          reverse[:suffix] &&= reverse[:suffix].sub(/^([^_])/, '_\1')
          reverse[:except] &&= Array.wrap(reverse[:except]).map(&:to_sym)
        end
        list = cfg[:values]
        list = I18n.t(list)             if list.is_a?(String)
        list = EnumType.pairs_for(list) if list.is_a?(Symbol)
        list = list.pairs               if list.is_a?(EnumType)
        list = list.map(&:to_s)         if list.is_a?(Array)
        cfg[:values] = list.presence
      end
    end

    # current_menu_config
    #
    # @param [Symbol, String]      menu_name
    # @param [Symbol, String, nil] type       Search type
    #
    # @return [Hash]
    #
    # @see #SEARCH_MENU_MAP
    #
    def current_menu_config(menu_name, type: nil, **)
      type &&= type.to_sym
      config = type && SEARCH_MENU_MAP[type] || SEARCH_MENU_BASE
      # noinspection RubyYardReturnMatch
      config[menu_name.to_sym] || {}
    end

    # Generate an array of label/value pairs to be used with #select_tag.
    #
    # @param [Symbol] menu_name
    # @param [Hash, String, Symbol, Class, Array<Array>] values
    # @param [Hash]   opt             Passed to #make_menu_label.
    #
    # @return [Array<Array<(String,String)>>]
    #
    # @overload make_menu(menu_name, entries, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Hash]          values       Configuration information.
    #
    # @overload make_menu(menu_name, i18n_scope, **opt)
    #   @param [Symbol]        menu_name
    #   @param [String]        i18n_scope
    #
    # @overload make_menu(menu_name, i18n_scope, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Symbol]        enum_type    Passed to EnumType.pairs_for.
    #
    # @overload make_menu(menu_name, enum_class, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Class]         enum_class
    #
    # @overload make_menu(menu_name, menu_pairs, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Array<Array>]  menu_pairs
    #
    def make_menu(menu_name, values, **opt)
      config = nil
      values =
        if values.is_a?(Hash)
          config = values
          if config[:menu].present?
            config[:menu]
          elsif config[:values].is_a?(Hash)
            config[:values].invert.to_a
          elsif config[:values].is_a?(Array)
            config[:values]
          else
            []
          end

        elsif values.is_a?(String)
          path = values
          path = "emma.#{path}" unless path.start_with?('emma.')
          I18n.t(path).invert

        elsif values.is_a?(Symbol)
          EnumType.pairs_for(values)&.invert.to_a

        elsif values.respond_to?(:pairs) && (pairs = value.pairs).present?
          pairs.invert.to_a

        elsif values.respond_to?(:values) && (list = values.values).present?
          Array.wrap(list)

        else
          Array.wrap(values)

        end
      pairs = values.compact.uniq

      # Transform a simple list of values into label/value pairs.
      unless pairs.first.is_a?(Array)
        pairs.map! { |v| [make_menu_label(menu_name, v, **opt), v.to_s] }
      end

      # Dynamically create reverse selections for the :sort menu if needed.
      config ||= current_menu_config(menu_name)
      reverse  = config[:reverse]
      if reverse && !false?(reverse)
        except = Array.wrap(reverse[:except]).map(&:to_s)
        pairs.flat_map do |pair|
          label, value = pair
          if except.include?(value)
            pair
          else
            label = sprintf(reverse[:label], sort: label)
            value = descending_sort(value, reverse[:suffix])
            [pair, [label, value]]
          end
        end
      else
        pairs
      end
    end

    # Format a menu label.
    #
    # @param [Symbol, String] menu_name
    # @param [String]         label       Original label text.
    # @param [Hash]           opt         Passed to #current_menu_config except
    #
    # @option opt [Symbol] :fmt           One of:
    #
    #   *nil*       No formatting.
    #   *false*     No formatting.
    #   :none       No formatting.
    #   :titleize   Format in "title case".
    #   :upcase     Format as all uppercase.
    #   :downcase   Format as all lowercase.
    #   Symbol      Other String method.
    #   *true*      Use :menu_format configuration value.
    #   (missing)   Use :menu_format configuration value.
    #
    # @return [String]
    #
    # == Usage Notes
    # This method is only engaged for menus with values that are not backed by
    # configuration information that maps values to labels.
    #
    def make_menu_label(menu_name, label, **opt)
      label  = label.to_s.squish
      format = opt[:fmt]
      format = :none if false?(format)
      unless format.is_a?(Symbol)
        format = current_menu_config(menu_name, **opt)[:menu_format]&.to_sym
      end
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

  # The names and properties of all of the search control menus and default
  # values.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  SEARCH_CONTROLS_CONFIG = I18n.t('emma.search_controls').deep_freeze

  # The value 'emma.search_controls._default' contains each of the properties
  # that can be expressed for a menu.  If a property there has a non-nil
  # value, then that value is used as the default for that property.
  #
  # @type [Hash{Symbol=>*}]
  #
  SEARCH_MENU_DEFAULT = SEARCH_CONTROLS_CONFIG[:_default].compact.deep_freeze

  # Properties for the "filter reset" button.
  #
  # @type [Hash{Symbol=>*}]
  #
  # @see #reset_menu
  #
  SEARCH_RESET_CONTROL =
    SEARCH_MENU_DEFAULT.merge(SEARCH_CONTROLS_CONFIG[:_reset]).deep_freeze

  # Base search control configurations.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_MENU_BASE_CONFIG =
    SEARCH_CONTROLS_CONFIG
      .reject { |name, _| (name == :layout) || name.to_s.start_with?('_') }
      .deep_freeze

  # The names and base properties of all of the search control menus.
  #
  # @type [Hash]
  #
  SEARCH_MENU_BASE =
    SEARCH_MENU_BASE_CONFIG.map { |menu_name, menu_config|
      [menu_name, search_menu_config(menu_name, menu_config)]
    }.to_h.deep_freeze

  # URL parameters for all search control menus.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_PARAMETERS =
    SEARCH_MENU_BASE.values.map { |config| config[:url_parameter] }.uniq.freeze

  # If a :sort parameter value ends with this, it indicates that the sort
  # should be performed in reverse order.
  #
  # @type [String]
  #
  REVERSE_SORT_SUFFIX = SEARCH_MENU_BASE.dig(:sort, :reverse, :suffix)

  # Search controls configurations for each controller configured to display
  # them.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_MENU_MAP =
    ApplicationHelper::APP_CONTROLLERS.map { |controller|
      [controller, search_controls_configs(controller)]
    }.compact.to_h.deep_freeze

  # Per-controller tables of the menu configurations associated with each
  # :url_parameter value.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_PARAMETER_MENU_MAP =
    SEARCH_MENU_MAP.map { |controller, controller_config|
      periodicals = %i[periodical edition].include?(controller)
      controller_config =
        controller_config.map { |menu_name, config|
          # noinspection RubyCaseWithoutElseBlockInspection
          case menu_name
            when :layout            then next
            when :format            then next if periodicals
            when :periodical_format then next unless periodicals
          end
          url_param = config[:url_parameter]&.to_sym
          [url_param, config] if url_param.present?
        }.compact.to_h
      [controller, controller_config]
    }.to_h.deep_freeze

  # Indicate whether the search control panel starts in the open state.
  #
  # @type [Boolean]
  #
  SEARCH_CONTROLS_INITIALLY_OPEN =
    SEARCH_CONTROLS_CONFIG.dig(:_self, :open).present?

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for advanced search values.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  ADV_SEARCH_CONFIG = I18n.t('emma.search_bar.advanced').deep_freeze

  # Label for button to open advanced search controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  ADV_SEARCH_OPENER_LABEL =
    non_breaking(ADV_SEARCH_CONFIG[:label]).html_safe.freeze

  # Tooltip for button to open advanced search controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  ADV_SEARCH_OPENER_TIP = ADV_SEARCH_CONFIG[:tooltip]

  # Label for button to close advanced search controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  ADV_SEARCH_CLOSER_LABEL =
    non_breaking(ADV_SEARCH_CONFIG.dig(:open, :label)).html_safe.freeze

  # Tooltip for button to close advanced search controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  ADV_SEARCH_CLOSER_TIP = ADV_SEARCH_CONFIG.dig(:open, :tooltip)

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
  # @param [String, Symbol] type      Default: `#search_target`.
  # @param [Hash]           opt       Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # @see en.emma.search_controls
  #
  def search_controls(type: nil, **opt)
    type = search_target(type)
    grid_rows = SEARCH_MENU_MAP.dig(type, :layout).deep_dup || [[]]
    grid_opt  = { type: type, row: 0 }
    grid_opt[:row_max] = grid_rows.size
    grid_opt[:col_max] = max_columns = grid_rows.map(&:size).max
    grid_rows.map! do |menus|
      grid_opt[:row] += 1
      grid_opt[:col]  = 0
      menus.map { |name|
        grid_opt[:col] += 1
        name   = name.presence || 'blank'
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
    append_css_classes!(opt, 'open') if SEARCH_CONTROLS_INITIALLY_OPEN
    html_div(safe_join(grid_rows, "\n"), opt)
  end

  # A control for toggling the visibility of advanced search controls.
  #
  # @param [Hash] opt                 Passed to #button_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def advanced_search_button(**opt)
    if SEARCH_CONTROLS_INITIALLY_OPEN
      label = ADV_SEARCH_CLOSER_LABEL
      tip   = ADV_SEARCH_CLOSER_TIP
    else
      label = ADV_SEARCH_OPENER_LABEL
      tip   = ADV_SEARCH_OPENER_TIP
    end
    opt = prepend_css_classes(opt, 'advanced-search-toggle')
    opt[:title] ||= tip
    opt[:type]  ||= 'button'
    button_tag(label, opt)
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
  # @see #search_controls
  # @see ParamsConcern#resolve_sort
  #
  # == Implementation Notes
  # This method produces a URL parameter (:sort) which is translated into the
  # appropriate pair of :sortOrder and :direction parameters by #resolve_sort.
  #
  def sort_menu(**opt)
    menu_name = :sort
    config    = current_menu_config(menu_name, **opt)
    params    = request_parameters
    direction = params[:direction]
    opt[:selected] ||= params[:sortOrder]
    opt[:selected] ||= params[config[:url_parameter]]
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
  # @see #search_controls
  # @see PaginationHelper#page_size
  #
  def size_menu(**opt)
    menu_name = :size
    config    = current_menu_config(menu_name, **opt)
    params    = request_parameters
    opt[:selected] ||= params[config[:url_parameter]]
    opt[:selected] ||= (page_size if respond_to?(:page_size))
    opt[:selected] = opt[:selected].first if opt[:selected].is_a?(Array)
    opt[:selected] = opt[:selected].to_i
    opt.delete(:selected) if opt[:selected].zero?
    menu_container(menu_name, **opt)
  end

  # An empty placeholder for a menu position.
  #
  # @param [Hash] opt                 Passed to #menu_spacer.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def blank_menu(**opt)
    # noinspection RubyYardReturnMatch
    menu_spacer(**opt) << menu_spacer(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A menu control preceded by a menu label (if provided).
  #
  # @param [String, Symbol] menu_name   Menu name.
  # @param [Hash]           opt         Passed to #menu_control except for:
  #
  # @option opt [String] :label         If missing, no label is included.
  # @option opt [String] :selected      Passed to #menu_control.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If menu is not available for *type*.
  #
  def menu_container(menu_name, **opt)
    local, opt = partition_options(opt, :label, :selected)
    label    = local[:label]
    selected = local[:selected]
    opt[:title] ||= menu_tooltip(menu_name, **opt)
    menu  = menu_control(menu_name, **opt.merge(selected: selected)) or return
    label = menu_label(menu_name, **opt.merge(label: label))
    # noinspection RubyYardReturnMatch
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
  # @param [String, Symbol] menu_name       Menu name.
  # @param [Hash]           opt             Passed to #label_tag except for
  #                                           #MENU_OPTS:
  #
  # @option opt [String, Symbol] :type      Passed to #search_form.
  # @option opt [String, Array]  :selected  Selected menu item(s).
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If menu is not available for *type*.
  #
  # @see HtmlHelper#grid_cell_classes
  #
  def menu_control(menu_name, **opt)
    opt, html_opt = partition_options(opt, *MENU_OPTS)
    type      = search_target(opt[:type])
    config    = current_menu_config(menu_name, type: type)
    url_param = config[:url_parameter]
    multiple  = config[:multiple]
    default   = config[:default]
    pairs     = config[:menu] || []
    any_label = nil
    any_value = ''

    # If any of the selected values are not already present in the menu, append
    # them now.
    selected = opt[:selected] || request_parameters[url_param] || default
    selected = Array.wrap(selected).map(&:to_s).uniq
    if selected.blank?
      selected = any_value
    else
      values = pairs.map { |_, value| value }
      added  = selected.reject { |sel| values.include?(sel) }
      if added.present?
        sorted = entries_sorted?(pairs)
        pairs += added.map { |sel| [make_menu_label(menu_name, sel), sel] }
        sort_entries!(pairs) if sorted
      end
    end

    # Prepend a placeholder if not present.
    if default.blank? && pairs.none? { |_, value| value == any_value }
      any_label = config[:placeholder] || '(select)'
      pairs = [[any_label, any_value]] + pairs unless multiple
    end

    # Add CSS classes which indicate the position of the control.
    prepend_grid_cell_classes!(html_opt, 'menu-control', **opt)
    search_form(url_param, type, **html_opt) do
      option_tags = options_for_select(pairs, selected)
      select_opt = {
        onchange:           'this.form.submit();',
        multiple:           multiple,
        'data-placeholder': any_label
      }
      select_tag(url_param, option_tags, reject_blanks(select_opt))
    end
  end

  # A label associated with a dropdown menu element.
  #
  # @param [String, Symbol] menu_name     Menu name.
  # @param [Hash]           opt           Passed to #label_tag except for
  #                                         #MENU_OPTS:
  #
  # @option opt [String] :label           Label text override.
  #
  # @return [ActiveSupport::SafeBuffer]   Empty if no label was present.
  #
  # @see HtmlHelper#prepend_grid_cell_classes!
  #
  def menu_label(menu_name, **opt)
    opt, html_opt = partition_options(opt, *MENU_OPTS)
    config = current_menu_config(menu_name, **opt)
    label  = opt[:label] || config[:label]
    return ''.html_safe if label.blank?

    if html_opt.delete(:sr_only) || false?(config[:label_visible])
      opt[:sr_only] = true
    else
      label = non_breaking(label)
    end
    opt.delete(:col_max) # Labels shouldn't have the 'col-last' CSS class.
    prepend_grid_cell_classes!(html_opt, 'menu-label', **opt)
    label_tag(config[:url_parameter], label, html_opt)
  end

  # menu_tooltip
  #
  # @param [String, Symbol] menu_name   Menu name.
  # @param [Hash]           opt         Passed to #current_menu_config.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [String]
  #
  def menu_tooltip(menu_name, **opt)
    menu_name = menu_name.to_sym
    config  = current_menu_config(menu_name, **opt)
    tooltip = config[:tooltip]
    warning = ('support this capability' if menu_name == :size)
    return tooltip unless warning
    tooltip = tooltip.dup
    tooltip << '.' unless tooltip.end_with?('.')
    tooltip << '&#013;' # newline
    tooltip << 'NOTE: The unified index does not yet ' << warning << '.'
    tooltip.html_safe
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
    # noinspection RubyYardReturnMatch
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
  # @see #SEARCH_RESET_CONTROL
  # @see #RESET_PARAMETERS
  # @see HtmlHelper#grid_cell_classes
  #
  def reset_button(**opt)
    opt, html_opt = partition_options(opt, :class, *MENU_OPTS)
    label = opt[:label] || SEARCH_RESET_CONTROL[:label]
    label = non_breaking(label)
    url   = opt[:url] || request_parameters.except(*RESET_PARAMETERS)
    url   = url_for(url) if url.is_a?(Hash)
    prepend_grid_cell_classes!(html_opt, 'reset', 'menu-button', **opt)
    html_opt[:title] ||= SEARCH_RESET_CONTROL[:tooltip]
    link_to(label, url, **html_opt)
  end

  # A button to reset all filter menu selections to their default state.
  #
  # @param [Hash] opt            Passed to #html_div except for #GRID_OPTS and:
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
    html_opt[:'aria-hidden'] = true
    html_div('&nbsp;'.html_safe, html_opt)
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
    menu.sort_by! { |lbl, val| val.is_a?(Integer) ? ('%09d' % val) : lbl }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # current_menu_config
  #
  # @param [Symbol, String]      menu_name
  # @param [Symbol, String, nil] type       Default: `#search_target`.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see ClassMethods#current_menu_config
  #
  def current_menu_config(menu_name, type: nil, **)
    super(menu_name, type: search_target(type))
  end

  # url_parameter_menu_config
  #
  # @param [Symbol, String]      url_param  The name of a URL parameter.
  # @param [Symbol, String, nil] type       Default: `#search_target`.
  #
  # @return [Hash]
  #
  # @see #SEARCH_PARAMETER_MENU_MAP
  #
  def url_parameter_menu_config(url_param, type: nil, **)
    type = search_target(type) || :search
    SEARCH_PARAMETER_MENU_MAP.dig(type, url_param.to_sym) || {}
  end

end

__loading_end(__FILE__)
