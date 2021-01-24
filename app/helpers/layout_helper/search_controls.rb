# app/helpers/layout_helper/search_controls.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::SearchControls
#
module LayoutHelper::SearchControls

  include LayoutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods

    def self.included(base)
      base.send(:extend, self)
    end

    include Emma::Common

    # =========================================================================
    # :section:
    # =========================================================================

    public

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
          reverse[:except] &&= Array.wrap(reverse[:except])
        end
        values = cfg[:values] || cfg[:menu]&.values
        values = I18n.t(values)             if values.is_a?(String)
        values = EnumType.pairs_for(values) if values.is_a?(Symbol)
        values = values.pairs               if values.is_a?(EnumType)
        values = values.map(&:to_s)         if values.is_a?(Array)
        cfg[:values] = values.presence
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
      type   = type&.to_sym
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
    #   @param [Hash]          entries      Configuration information.
    #   @param [Hash]          opt
    #
    # @overload make_menu(menu_name, i18n_scope, **opt)
    #   @param [Symbol]        menu_name
    #   @param [String]        i18n_scope
    #   @param [Hash]          opt
    #
    # @overload make_menu(menu_name, enum_type, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Symbol]        enum_type    Passed to EnumType.pairs_for.
    #   @param [Hash]          opt
    #
    # @overload make_menu(menu_name, enum_class, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Class]         enum_class
    #   @param [Hash]          opt
    #
    # @overload make_menu(menu_name, menu_pairs, **opt)
    #   @param [Symbol]        menu_name
    #   @param [Array<Array>]  menu_pairs
    #   @param [Hash]          opt
    #
    def make_menu(menu_name, values, **opt)
      config  = values.is_a?(Hash) ? values : current_menu_config(menu_name)
      pairs   = config[:menu]
      pairs ||=
        case values
          when Hash
            (val = values[:values]).is_a?(Hash) ? val.invert : val
          when Array
            values
          when String
            path = values
            path = "emma.#{path}" unless path.start_with?('emma.')
            I18n.t(path, default: {}).invert
          when Symbol
            EnumType.pairs_for(values)&.invert
          else
            val   = (values.pairs.presence  if values.respond_to?(:pairs))
            val ||= (values.values.presence if values.respond_to?(:values))
            val ||= values
            val.is_a?(Hash) ? val.invert : val
        end

      # Transform a simple list of values into label/value pairs.
      if pairs.is_a?(Hash)
        pairs = pairs.transform_values(&:to_s).to_a
      else
        pairs = Array.wrap(pairs).compact
        pairs.uniq!
        pairs.map! { |v| [make_menu_label(menu_name, v, **opt), v.to_s] }
      end

      # Dynamically create reverse selections for the :sort menu if needed.
      add_reverse_pairs(pairs, config)
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

    protected

    # Create reverse sort entries.
    #
    # @param [Array<Array<String,*>>] pairs
    # @param [Hash]                   config
    #
    # @return [Array<Array<String,String>>]
    #
    def add_reverse_pairs(pairs, config)
      config = config[:reverse] if config.is_a?(Hash) && config.key?(:reverse)
      return pairs unless config.is_a?(Hash) && true?(config[:enabled])
      except = Array.wrap(config[:except])
      pairs.flat_map do |fwd_pair|
        label, value = fwd_pair = fwd_pair.map(&:to_s)
        rev_pair =
          unless except.include?(value)
            rev_label = sprintf(config[:label], sort: label)
            rev_value = descending_sort(value, config[:suffix])
            [rev_label, rev_value]
          end
        [fwd_pair, rev_pair].compact
      end
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
    # @return [String]                Value for :sortOrder parameter.
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
    # @return [String]                Value for :sortOrder parameter.
    # @return [nil]                   If *value* is blank.
    #
    def descending_sort(value, suffix = nil)
      return if (value = value.to_s).blank?
      suffix ||= REVERSE_SORT_SUFFIX
      value.end_with?(suffix) ? value : "#{value}#{suffix}"
    end

  end

  include ClassMethods

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
  SEARCH_CONTROLS_ROOT = I18n.t('emma.search_controls').deep_freeze

  # The value 'en.emma.search_controls._default' contains each of the
  # properties that can be expressed for a menu.  If a property there has a
  # non-nil value, then that value is used as the default for that property.
  #
  # @type [Hash{Symbol=>*}]
  #
  SEARCH_MENU_DEFAULT = SEARCH_CONTROLS_ROOT[:_default].compact.deep_freeze

  # Properties for the "filter reset" button.
  #
  # @type [Hash{Symbol=>*}]
  #
  # @see #reset_menu
  #
  SEARCH_RESET_CONTROL =
    SEARCH_MENU_DEFAULT.merge(SEARCH_CONTROLS_ROOT[:_reset]).deep_freeze

  # The names and base properties of all of the search control menus.
  #
  # @type [Hash]
  #
  SEARCH_MENU_BASE =
    SEARCH_CONTROLS_ROOT.map { |menu_name, menu_config|
      next if menu_name.start_with?('_') || !menu_config.is_a?(Hash)
      [menu_name, search_menu_config(menu_name, menu_config)]
    }.compact.to_h.deep_freeze

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

  # Search controls configurations for each controller where they are enabled.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_CONTROLS_CONFIG =
    ApplicationHelper::APP_CONTROLLERS.map { |controller|
      control_configs = SEARCH_CONTROLS_ROOT.deep_dup
      %W(generic #{controller} #{controller}.generic).each do |section|
        section_cfg = I18n.t("emma.#{section}.search_controls", default: nil)
        control_configs.deep_merge!(section_cfg) if section_cfg.present?
      end
      enabled = control_configs[:enabled]
      enabled = enabled.is_a?(Array) ? enabled.map(&:to_s) : true?(enabled)
      [controller, control_configs] if (control_configs[:enabled] = enabled)
    }.compact.to_h.deep_freeze

  # Search control menu configurations for each controller configured to
  # display them.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_MENU_MAP =
    SEARCH_CONTROLS_CONFIG.transform_values { |control_configs|
      control_configs.map { |menu_name, menu_config|
        next if %i[enabled expanded].include?(menu_name)
        next if menu_name.start_with?('_')
        if menu_config.is_a?(Hash)
          menu_config = search_menu_config(menu_name, menu_config)
          menu_config[:menu] = make_menu(menu_name, menu_config).presence
        end
        [menu_name, menu_config]
      }.compact.to_h
    }.deep_freeze

  # Per-controller tables of the menu configurations associated with each
  # :url_parameter value.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_PARAMETER_MENU_MAP =
    SEARCH_MENU_MAP.map { |controller, menu_configs|
      periodicals = %i[periodical edition].include?(controller)
      search_param_menu_configs =
        menu_configs.map { |menu_name, menu_config|
          # noinspection RubyCaseWithoutElseBlockInspection
          case menu_name
            when :layout            then next
            when :format            then next if periodicals
            when :periodical_format then next unless periodicals
          end
          url_param = menu_config[:url_parameter]&.to_sym
          [url_param, menu_config] if url_param.present?
        }.compact.to_h
      [controller, search_param_menu_configs]
    }.to_h.deep_freeze

  # Indicate whether the search control panel starts in the open state.
  #
  # @type [Boolean]
  #
  SEARCH_CONTROLS_INITIALLY_OPEN = SEARCH_CONTROLS_ROOT[:expanded].present?

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
    p     ||= request_parameters
    type    = search_target(p)
    enabled = SEARCH_CONTROLS_CONFIG.dig(type, :enabled)
    enabled = enabled.include?(p[:action].to_s) if enabled.is_a?(Array)
    enabled
  end

  # One or more rows of controls.
  #
  # @param [String, Symbol] type          Default: `#search_target`.
  # @param [Hash]           opt           Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no controls were found for *type*.
  #
  # @see file:config/locales/en.yml en.emma.search_controls
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
    prepend_css_classes!(opt, 'search-controls', "columns-#{max_columns}")
    append_css_classes!(opt, 'open') if SEARCH_CONTROLS_INITIALLY_OPEN
    html_div(opt) { grid_rows }
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
    prepend_css_classes!(opt, 'advanced-search-toggle')
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
  # (Default: `params[:sortOrder]`.)
  #
  # @param [Hash] opt                   Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
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
  # @param [Hash] opt                   Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
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

  # Specify initial number of entries per object key.
  #
  # @param [Hash] opt                   Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
  #
  # @see #search_controls
  #
  def prefix_limit_menu(**opt)
    menu_name = :prefix_limit
    config    = current_menu_config(menu_name, **opt)
    params    = request_parameters
    opt[:selected] ||= params[config[:url_parameter]]
    opt[:selected] = opt[:selected].first if opt[:selected].is_a?(Array)
    opt[:selected] = opt[:selected].to_i
    opt.delete(:selected) if opt[:selected].zero?
    menu_container(menu_name, **opt)
  end

  # Filter on deployment.
  #
  # @param [Hash] opt                 Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
  #
  # @see #search_controls
  #
  def deployment_menu(**opt)
    menu_name = :deployment
    config    = current_menu_config(menu_name, **opt)
    params    = request_parameters
    opt[:selected] ||= params[config[:url_parameter]]
    opt[:selected] ||= application_deployment
    opt[:selected] = opt[:selected].first if opt[:selected].is_a?(Array)
    opt.delete(:selected) if opt[:selected].blank?
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
  # @return [ActiveSupport::SafeBuffer] HTML label and control elements.
  # @return [nil]                       If menu is not available for *type*.
  #
  def menu_container(menu_name, **opt)
    local, opt = partition_options(opt, :label, :selected)
    label    = local[:label]
    selected = local[:selected]
    opt[:title] ||= menu_tooltip(menu_name, **opt)
    l_id  = "#{menu_name}_label"
    m_opt = opt.merge(selected: selected, label_id: l_id)
    menu  = menu_control(menu_name, **m_opt) or return
    label = menu_label(menu_name, **opt.merge(label: label, id: l_id))
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
  # @param [Hash]           opt             Passed to #search_form except for
  #                                           :label_id and #MENU_OPTS:
  #
  # @option opt [String, Symbol] :type      Passed to #search_form.
  # @option opt [String, Array]  :selected  Selected menu item(s).
  # @option opt [String, Symbol] :label_id  ID of associated label element.
  #
  # @return [ActiveSupport::SafeBuffer]     HTML menu element.
  # @return [nil]                           If menu is not available for *type*.
  #
  # @see HtmlHelper#grid_cell_classes
  #
  def menu_control(menu_name, **opt)
    opt, html_opt = partition_options(opt, :label_id, *MENU_OPTS)
    type      = search_target(opt[:type]) or return
    config    = current_menu_config(menu_name, type: type)
    url_param = config[:url_parameter]
    multiple  = config[:multiple]
    default   = config[:default]
    pairs     = config[:menu] || []
    label_id  = opt.delete(:label_id)
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
        'aria-labelledby':  label_id,
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
  # @return [String]                    Tooltip text.
  # @return [nil]                       If no tooltip was defined.
  #
  def menu_tooltip(menu_name, **opt)
    current_menu_config(menu_name, **opt)[:tooltip]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Date selection for the end of a date range.
  #
  # @param [Hash] opt                   Passed to #date_menu.
  #
  # @return [ActiveSupport::SafeBuffer] HTML label and control elements.
  # @return [nil]                       If menu is not available.
  #
  def before_menu(**opt)
    date_container(:before, **opt)
  end

  # Date selection for the beginning of a date range.
  #
  # @param [Hash] opt                   Passed to #date_menu.
  #
  # @return [ActiveSupport::SafeBuffer] HTML label and control elements.
  # @return [nil]                       If menu is not available.
  #
  def after_menu(**opt)
    date_container(:after, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A date control preceded by a label (if provided).
  #
  # @param [String, Symbol] name          Control name.
  # @param [Hash]           opt           Passed to #date_control except for:
  #
  # @option opt [String] :label           Label text override.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML label and control elements.
  # @return [nil]                         If menu is not available.
  #
  def date_container(name, **opt)
    opt[:config] ||= current_menu_config(name, **opt)
    opt[:title]  ||= date_tooltip(name, **opt)
    l_id  = "#{name}_label"
    ctrl  = date_control(name, **opt.merge(label_id: l_id)) or return
    label = date_label(name, **opt.merge(id: l_id))
    # noinspection RubyYardReturnMatch
    label << ctrl
  end

  # A date selection element.
  #
  # If *selected* is not specified `#SEARCH_MENU[name][:url_parameter]` is
  # used to extract a value from `#request_parameters`.
  #
  # If no option is currently selected, an initial "null" selection is
  # prepended.
  #
  # @param [String, Symbol] name        Control name.
  # @param [Hash]           opt         Passed to #search_form except for
  #                                       :label_id and #MENU_OPTS:
  #
  # @option opt [Date, String]   :selected  Initial value.
  # @option opt [String, Symbol] :type      Passed to #search_form.
  # @option opt [String, Symbol] :label_id  ID of associated label element.
  #
  # @return [ActiveSupport::SafeBuffer]     HTML menu element.
  # @return [nil]                           If menu is not available.
  #
  # @see HtmlHelper#grid_cell_classes
  #
  def date_control(name, **opt)
    opt, html_opt = partition_options(opt, :label_id, *MENU_OPTS)
    type      = search_target(opt[:type]) or return
    label_id  = opt.delete(:label_id)
    config    = opt.delete(:config) || current_menu_config(name, type: type)
    url_param = config[:url_parameter]
    default   = config[:default]

    # Get the initial value for the field.
    value = opt.delete(:selected) || request_parameters[url_param] || default

    # Add CSS classes which indicate the position of the control.
    prepend_grid_cell_classes!(html_opt, 'date-control', **opt)
    search_form(url_param, type, **html_opt) do
      date_opt = { onchange: 'this.form.submit();' }
      date_opt[:'aria-labelledby'] = label_id if label_id.present?
      date_field_tag(url_param, value, reject_blanks(date_opt))
    end
  end

  # A label associated with a dropdown menu element.
  #
  # @param [String, Symbol] name          Control name.
  # @param [Hash]           opt           Passed to #label_tag except for
  #                                         #MENU_OPTS:
  #
  # @option opt [String] :label           Label text override.
  #
  # @return [ActiveSupport::SafeBuffer]   Empty if no label was configured or
  #                                         provided.
  #
  # @see HtmlHelper#prepend_grid_cell_classes!
  #
  def date_label(name, **opt)
    opt, html_opt = partition_options(opt, *MENU_OPTS)
    config = opt.delete(:config) || current_menu_config(name, **opt)
    label  = opt[:label] || config[:label]
    return ''.html_safe if label.blank?

    if html_opt.delete(:sr_only) || false?(config[:label_visible])
      opt[:sr_only] = true
    else
      label = non_breaking(label)
    end
    opt.delete(:col_max) # Labels shouldn't have the 'col-last' CSS class.
    prepend_grid_cell_classes!(html_opt, 'date-label', **opt)
    label_tag(config[:url_parameter], label, html_opt)
  end

  # date_tooltip
  #
  # @param [String, Symbol] name        Control name.
  # @param [Hash]           opt         Passed to #current_menu_config.
  #
  # @return [String]                    Tooltip text.
  # @return [nil]                       If no tooltip was defined.
  #
  def date_tooltip(name, **opt)
    config = opt.delete(:config) || current_menu_config(name, **opt)
    config[:tooltip]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The controls for resetting filter menu selections to their default state.
  #
  # @param [Hash] opt                 Passed to #menu_spacer and #reset_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def reset_menu(**opt)
    append_css_classes!(opt, 'reset')
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
  # @see #reset_parameters
  # @see HtmlHelper#grid_cell_classes
  #
  def reset_button(**opt)
    opt, html_opt = partition_options(opt, :class, *MENU_OPTS)
    label = opt[:label] || SEARCH_RESET_CONTROL[:label]
    label = non_breaking(label)
    url   = opt[:url] || reset_parameters
    url   = url_for(url) if url.is_a?(Hash)
    prepend_grid_cell_classes!(html_opt, 'reset', 'menu-button', **opt)
    html_opt[:title] ||= SEARCH_RESET_CONTROL[:tooltip]
    link_to(label, url, **html_opt)
  end

  # URL parameters that should be cleared for the current search type.
  #
  # @param [Hash] opt                 Default: `#request_parameters`.
  #
  # @return [Hash]
  #
  def reset_parameters(opt = nil)
    opt ||= request_parameters
    type  = search_target(opt[:controller])
    keys  = SEARCH_PARAMETER_MENU_MAP[type]&.keys || []
    keys -= SearchTermsHelper::SEARCH_KEYS
    opt.except(*keys)
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
    menu.sort_by! { |lbl, val| val.is_a?(Integer) ? ('%09d' % val) : lbl.to_s }
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
