# app/helpers/layout_helper/search_filters.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the '<header>' search filter controls.
#
module LayoutHelper::SearchFilters

  include LayoutHelper::Common

  include GridHelper
  include ParamsHelper
  include SearchModesHelper

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
        cfg[:url_param]     = (cfg[:url_param] || menu_name)&.to_sym
        if (reverse = cfg[:reverse])
          reverse[:suffix] &&= reverse[:suffix].sub(/^([^_])/, '_\1')
          reverse[:except] &&= Array.wrap(reverse[:except])
        end
        default   = cfg[:default] || cfg[:_default]
        values    = cfg[:values]  || cfg[:menu]&.values
        default ||= EnumType.default_for(values) if values.is_a?(Symbol)
        values    = EnumType.pairs_for(values)   if values.is_a?(Symbol)
        default ||= values.default               if values.is_a?(EnumType)
        values    = values.pairs                 if values.is_a?(EnumType)
        values    = values.map(&:to_s)           if values.is_a?(Array)
        default   = default.to_sym               if default.is_a?(String)
        cfg[:values]  = values.presence
        cfg[:default] = default.presence
      end
    end

    # current_menu_config
    #
    # @param [Symbol, String]      menu_name
    # @param [Symbol, String, nil] target     Target search controller.
    #
    # @return [Hash]
    #
    # @see #SEARCH_MENU_MAP
    #
    def current_menu_config(menu_name, target: nil, **)
      target = target&.to_sym
      config = target && SEARCH_MENU_MAP[target] || SEARCH_MENU_BASE
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
    #--
    # noinspection RubyMismatchedArgumentType
    #++
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
            # noinspection RailsParamDefResolve
            val   = values.try(:pairs).presence
            val ||= values.try(:values).presence
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
    # @param [Array<Array<String,Any>>] pairs
    # @param [Hash]                     config
    #
    # @return [Array<Array<String,String>>]
    #
    def add_reverse_pairs(pairs, config)
      return pairs unless config.is_a?(Hash)
      return pairs unless (config = config[:reverse]).is_a?(Hash)
      return pairs unless true?(config[:enabled])
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

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  include ClassMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The names and properties of all of the search filter menus and default
  # values.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection, RubyMismatchedConstantType
  #++
  SEARCH_FILTERS_ROOT = I18n.t('emma.search_filters').deep_freeze

  # The value 'en.emma.search_filters._default' contains each of the properties
  # that can be expressed for a menu.  If a property there has a non-nil value,
  # then that value is used as the default for that property.
  #
  # @type [Hash{Symbol=>Any}]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  SEARCH_MENU_DEFAULT = SEARCH_FILTERS_ROOT[:_default].compact.deep_freeze

  # Properties for the "filter reset" button.
  #
  # @type [Hash{Symbol=>Any}]
  #
  # @see #reset_menu
  #
  SEARCH_RESET_CONTROL =
    SEARCH_MENU_DEFAULT.merge(SEARCH_FILTERS_ROOT[:_reset]).deep_freeze

  # The names and base properties of all of the search control menus.
  #
  # @type [Hash]
  #
  SEARCH_MENU_BASE =
    SEARCH_FILTERS_ROOT.map { |menu_name, menu_config|
      next if menu_name.start_with?('_') || !menu_config.is_a?(Hash)
      [menu_name, search_menu_config(menu_name, menu_config)]
    }.compact.to_h.deep_freeze

  # URL parameters for all search control menus.
  #
  # @type [Array<Symbol>]
  #
  # @note Currently unused.
  #
  SEARCH_PARAMETERS =
    SEARCH_MENU_BASE.values.map { |config| config[:url_param] }.uniq.freeze

  # If a :sort parameter value ends with this, it indicates that the sort
  # should be performed in reverse order.
  #
  # @type [String]
  #
  REVERSE_SORT_SUFFIX = SEARCH_MENU_BASE.dig(:sort, :reverse, :suffix)

  # Search filter configurations for each controller where they are enabled.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_FILTERS_CONFIG =
    ApplicationHelper::APP_CONTROLLERS.map { |controller|
      filter_configs = SEARCH_FILTERS_ROOT.deep_dup
      %W(generic #{controller} #{controller}.generic).each do |section|
        section_cfg = I18n.t("emma.#{section}.search_filters", default: nil)
        filter_configs.deep_merge!(section_cfg) if section_cfg.present?
      end
      enabled = filter_configs[:enabled]
      enabled = enabled.is_a?(Array) ? enabled.map(&:to_s) : true?(enabled)
      [controller, filter_configs] if (filter_configs[:enabled] = enabled)
    }.compact.to_h.deep_freeze

  # Search control menu configurations for each controller configured to
  # display them.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_MENU_MAP =
    SEARCH_FILTERS_CONFIG.transform_values { |control_configs|
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
  # :url_param value.
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
          url_param = menu_config[:url_param]&.to_sym
          [url_param, menu_config] if url_param.present?
        }.compact.to_h
      [controller, search_param_menu_configs]
    }.to_h.deep_freeze

  # Indicate whether the search control panel starts in the open state.
  #
  # @type [Boolean]
  #
  SEARCH_FILTERS_START_EXPANDED = SEARCH_FILTERS_ROOT[:expanded].present?

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for advanced search values.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection, RubyMismatchedConstantType
  #++
  ADV_SEARCH_CONFIG = I18n.t('emma.search_bar.advanced').deep_freeze

  # Labels/tooltips for expanding and contracting search filters.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String,ActiveSupport::SafeBuffer}}]
  #
  ADV_SEARCH = {
    opener: {
      label:    non_breaking(ADV_SEARCH_CONFIG[:label]).html_safe,
      tooltip:  ADV_SEARCH_CONFIG[:tooltip],
    },
    closer: {
      label:    non_breaking(ADV_SEARCH_CONFIG.dig(:open, :label)).html_safe,
      tooltip:  ADV_SEARCH_CONFIG.dig(:open, :tooltip)
    }
  }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the search filter controls.
  #
  # @param [Hash, nil] opt            Default: `#request_parameters`.
  #
  def show_search_filters?(opt = nil)
    opt   ||= request_parameters
    target  = search_target(**opt)
    # noinspection RubyMismatchedArgumentType
    enabled = SEARCH_FILTERS_CONFIG.dig(target, :enabled)
    enabled = enabled.include?(opt[:action].to_s) if enabled.is_a?(Array)
    enabled.present?
  end

  # One or more rows of search filter controls.
  #
  # @param [String, Symbol] target        Default: `#search_target`.
  # @param [Hash]           opt           Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         No controls were found for *target*.
  #
  # @see file:config/locales/en.yml *en.emma.search_filters*
  # @see #blank_menu
  # @see #sort_menu
  # @see #size_menu
  # @see #repository_menu
  # @see #prefix_limit_menu
  # @see #deployment_menu
  # @see #generic_menu
  # @see #before_menu
  # @see #after_menu
  # @see #reset_menu
  #
  def search_filter_container(target: nil, **opt)
    target    = search_target(target) or return
    config    = SEARCH_MENU_MAP[target]   || {}
    grid_rows = config[:layout]&.deep_dup || [[]]
    grid_opt  = { target: target, row: 0 }
    grid_opt[:row_max] = grid_rows.size
    grid_opt[:col_max] = max_columns = grid_rows.map(&:size).max
    grid_rows.map! do |menus|
      grid_opt[:row] += 1
      grid_opt[:col]  = 0
      menus.map { |name|
        grid_opt[:col] += 1
        name  = name.to_s.presence&.delete_suffix('_menu')&.to_sym || :blank
        meth  = :"#{name}_menu"
        meth  = :generic_menu unless respond_to?(meth, true)
        guard = config.dig(name, :active)
        if guard.nil? || permitted_by?(guard)
          menu_opt = grid_opt
        else
          menu_opt = grid_opt.merge(disabled: true)
        end
        send(meth, name, **menu_opt)
      }.compact.tap { |columns|
        grid_opt[:row] -= 1 if columns.blank?
      }.presence
    end
    grid_rows.compact!
    return if grid_rows.blank?
    prepend_css!(opt, 'search-filter-container', "columns-#{max_columns}")
    append_css!(opt, 'open') if SEARCH_FILTERS_START_EXPANDED
    # noinspection RubyMismatchedReturnType
    html_div(opt) { grid_rows }
  end

  # A control for toggling the visibility of advanced search filter controls.
  #
  # @param [Hash] opt                 Passed to #button_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def advanced_search_button(**opt)
    css           = '.advanced-search-toggle'
    control       = SEARCH_FILTERS_START_EXPANDED ? :closer : :opener
    opt[:type]  ||= 'button'
    opt[:title] ||= ADV_SEARCH[control][:tooltip]
    label         = ADV_SEARCH[control][:label]
    prepend_css!(opt, css)
    button_tag(label, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A hidden HTML elements which indicates that the page has been constructed
  # with search filters which cause a new search whenever a value is selected.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def immediate_search_marker
    css = '.immediate-search-marker'
    if immediate_search?
      html_div('immediate', class: css_classes(css, 'hidden'))
    end
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
  # @see GridHelper#GRID_OPTS
  #
  MENU_OPTS = [:target, :label, :selected, *GRID_OPTS].freeze

  # An empty placeholder for a menu position.
  #
  # @param [Hash] opt                 Passed to #menu_spacer.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def blank_menu(*, **opt)
    # noinspection RubyMismatchedReturnType
    menu_spacer(**opt) << menu_spacer(**opt)
  end

  # Perform a search specifying a collation order for the results.
  # (Default: `params[:sortOrder]`.)
  #
  # @param [Symbol] menu_name           Control name (should be :sort).
  # @param [Hash]   opt                 Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
  #
  # @see ParamsConcern#resolve_sort
  #
  # == Implementation Notes
  # This method produces a URL parameter (:sort) which is translated into the
  # appropriate pair of :sortOrder and :direction parameters by #resolve_sort.
  #
  def sort_menu(menu_name, **opt)
    prm       = request_parameters
    direction = prm[:direction]
    opt[:selected] ||= prm[:sort] || prm[:sortOrder]
    opt[:selected] &&= descending_sort(opt[:selected]) if direction == 'desc'
    append_css!(opt, 'non-search')
    menu_container(menu_name, **opt)
  end

  # Perform a search specifying a results page size.
  #
  # @param [Symbol] menu_name           Control name (should be :size).
  # @param [Hash]   opt                 Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
  #
  # @see Paginator#page_size
  #
  def size_menu(menu_name, **opt)
    opt[:config]     = config = current_menu_config(menu_name, **opt)
    opt[:default]  ||= opt.dig(:config, :default) || @page.page_size
    url_param        = (config[:url_param] || menu_name).to_sym
    opt[:selected] ||= request_parameters[url_param]
    opt[:selected] ||= opt[:default]
    opt[:selected]   = opt[:selected].first if opt[:selected].is_a?(Array)
    opt[:selected]   = opt[:selected].to_i
    opt.delete(:selected) if opt[:selected].zero?
    append_css!(opt, 'non-search')
    menu_container(menu_name, **opt)
  end

  # Filter on repository.
  #
  # @param [Symbol] menu_name           Control name (should be :repository).
  # @param [Hash]   opt                 Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
  #
  def repository_menu(menu_name, **opt)
    opt[:default] = nil
    menu_container(menu_name, **opt)
  end

  # Specify initial number of entries per object key.
  #
  # @param [Symbol] menu_name           Control name (should be :prefix_limit).
  # @param [Hash]   opt                 Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
  #
  def prefix_limit_menu(menu_name, **opt)
    opt[:selected] = opt[:selected].first if opt[:selected].is_a?(Array)
    opt[:selected] = opt[:selected].to_i
    opt.delete(:selected) if opt[:selected].zero?
    menu_container(menu_name, **opt)
  end

  # Filter on deployment.
  #
  # @param [Symbol] menu_name           Control name (should be :deployment).
  # @param [Hash]   opt                 Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
  #
  def deployment_menu(menu_name, **opt)
    opt[:config]     = config = current_menu_config(menu_name, **opt)
    opt[:default]    = nil
    url_param        = (config[:url_param] || menu_name).to_sym
    opt[:selected] ||= request_parameters[url_param]
    opt[:selected]   = opt[:selected].first if opt[:selected].is_a?(Array)
    opt.delete(:selected) if opt[:selected].blank?
    menu_container(menu_name, **opt)
  end

  # Any menu without a specific method.
  #
  # @param [Symbol] menu_name           Control name.
  # @param [Hash]   opt                 Passed to #menu_container.
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       Menu is not available in this context.
  #
  #--
  # noinspection DuplicatedCode
  #++
  def generic_menu(menu_name, **opt)
    menu_container(menu_name, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A menu control preceded by a menu label (if provided).
  #
  # @param [Symbol]              menu_name  Control name.
  # @param [String, nil]         label      Label text passed to #menu_label.
  # @param [String, Symbol, nil] target     Search target controller.
  # @param [Hash]                opt        Passed to #menu_control.
  #
  # @return [ActiveSupport::SafeBuffer]     HTML label and control elements.
  # @return [nil]                           Menu is not available for *target*.
  #
  #--
  # noinspection DuplicatedCode
  #++
  def menu_container(menu_name, label: nil, target: nil, **opt)
    opt[:target]   = search_input_target(target)
    opt[:config] ||= current_menu_config(menu_name, **opt)
    opt[:title]  ||= menu_tooltip(menu_name, **opt)
    l_id  = "#{menu_name}_label"
    l_opt = m_opt = opt
    if opt[:disabled]
      append_css!(opt, :disabled)
      note  = 'NOTE: this value is fixed for results by title.' # TODO: I18n
      m_opt = opt.merge(title: [opt[:title], note].compact.join("\n"))
    end
    menu  = menu_control(menu_name, label_id: l_id, **m_opt) or return
    label = menu_label(menu_name, label: label, id: l_id, **l_opt)
    # noinspection RubyMismatchedReturnType
    label << menu
  end

  # A dropdown menu element.
  #
  # If *selected* is not specified `#SEARCH_MENU[menu_name][:url_param]` is
  # used to extract a value from `#request_parameters`.
  #
  # If no option is currently selected, an initial "null" selection is
  # prepended.
  #
  # Normally the element is a '<div>' but if #immediate_search? is true then it
  # is a '<form>' which allows the enclosed '<select>' to perform a new
  # modified search upon selection.
  #
  # @param [Symbol]              menu_name  Control name.
  # @param [String, Symbol, nil] target     Passed to #search_form.
  # @param [String, Array, nil]  selected   Selected menu item(s).
  # @param [String, Symbol, nil] label_id   ID of associated label element.
  # @param [Boolean, nil]        disabled
  # @param [Hash]                opt        Passed to #search_form except for
  #                                           #MENU_OPTS and:
  #
  # @option opt [Any]  :default             Provided default value.
  # @option opt [Hash] :config              Pre-fetched menu configuration.
  #
  # @return [ActiveSupport::SafeBuffer]     HTML menu element.
  # @return [nil]                           If menu unavailable for *target*.
  #
  # @see GridHelper#grid_cell_classes
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def menu_control(
    menu_name,
    target:   nil,
    selected: nil,
    label_id: nil,
    disabled: nil,
    **opt
  )
    css       = '.menu-control'
    target    = search_target(target) or return
    html_opt  = remainder_hash!(opt, :config, :default, *MENU_OPTS)
    config    = opt[:config]  || current_menu_config(menu_name, target: target)
    pairs     = config[:menu] || []
    default   = opt.key?(:default) ? opt[:default] : config[:default]
    url_param = (config[:url_param] || menu_name).to_sym
    multiple  = config[:multiple]
    mode      = multiple ? 'multiple' : 'single'
    any_label = config[:placeholder] || '(select)' # TODO: I18n
    any_value = ''

    # If any of the selected values are not already present in the menu, append
    # them now.
    selected ||= request_parameters[url_param] || default
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
      pairs = [[any_label, any_value]] + pairs unless multiple
    end

    # Setup the <select> menu element.
    option_tags = options_for_select(pairs, selected)
    select_opt  = { 'data-placeholder': any_label, 'data-default': default }
    select_opt[:'aria-labelledby'] = label_id              if label_id
    select_opt[:multiple]          = multiple              if multiple
    select_opt[:disabled]          = disabled              if disabled
    select_opt[:onchange]          = 'this.form.submit();' if immediate_search?
    menu = select_tag(url_param, option_tags, select_opt)

    # Add CSS classes which indicate the position of the control.
    prepend_grid_cell_classes!(html_opt, css, mode, **opt)
    if immediate_search?
      search_form(target, url_param, **html_opt) { menu }
    else
      html_div(html_opt) { menu }
    end
  end

  # A label associated with a dropdown menu element.
  #
  # @param [String, Symbol] menu_name     Control name.
  # @param [Hash]           opt           Passed to #control_label.
  #
  # @return [ActiveSupport::SafeBuffer]   Empty if no label was present.
  #
  #--
  # noinspection DuplicatedCode
  #++
  def menu_label(menu_name, **opt)
    css = '.menu-label'
    append_css!(opt, css)
    control_label(menu_name, **opt)
  end

  # menu_tooltip
  #
  # @param [String, Symbol] menu_name   Control name.
  # @param [Hash]           opt         Passed to #config_tooltip.
  #
  # @return [String]                    Tooltip text.
  # @return [nil]                       If no tooltip was defined.
  #
  #--
  # noinspection DuplicatedCode
  #++
  def menu_tooltip(menu_name, **opt)
    config_tooltip(menu_name, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Date selection for the end of a date range.
  #
  # @param [Symbol] menu_name           Control name (should be :before).
  # @param [Hash]   opt                 Passed to #date_container.
  #
  # @return [ActiveSupport::SafeBuffer] HTML label and control elements.
  # @return [nil]                       If menu is not available.
  #
  #--
  # noinspection DuplicatedCode
  #++
  def before_menu(menu_name, **opt)
    date_container(menu_name, **opt)
  end

  # Date selection for the beginning of a date range.
  #
  # @param [Symbol] menu_name           Control name (should be :after).
  # @param [Hash]   opt                 Passed to #date_container.
  #
  # @return [ActiveSupport::SafeBuffer] HTML label and control elements.
  # @return [nil]                       If menu is not available.
  #
  #--
  # noinspection DuplicatedCode
  #++
  def after_menu(menu_name, **opt)
    date_container(menu_name, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A date control preceded by a label (if provided).
  #
  # @param [Symbol]              menu_name  Control name.
  # @param [String, nil]         label      Label text passed to #date_label.
  # @param [String, Symbol, nil] target     Search target controller.
  # @param [Hash]                opt        Passed to #date_control.
  #
  # @return [ActiveSupport::SafeBuffer]     HTML label and control elements.
  # @return [nil]                           Menu is not available for *target*.
  #
  # @see #menu_container
  #
  #--
  # noinspection DuplicatedCode
  #++
  def date_container(menu_name, label: nil, target: nil, **opt)
    opt[:target]   = search_input_target(target)
    opt[:config] ||= current_menu_config(menu_name, **opt)
    opt[:title]  ||= date_tooltip(menu_name, **opt)
    l_id  = "#{menu_name}_label"
    ctrl  = date_control(menu_name, label_id: l_id, **opt) or return
    label = date_label(menu_name, label: label, id: l_id, **opt)
    # noinspection RubyMismatchedReturnType
    label << ctrl
  end

  # A date selection element.
  #
  # If *selected* is not specified `#SEARCH_MENU[name][:url_param]` is used to
  # extract a value from `#request_parameters`.
  #
  # If no option is currently selected, an initial "null" selection is
  # prepended.
  #
  # @param [Symbol]              menu_name  Control name.
  # @param [String, Symbol, nil] target     Search target controller.
  # @param [String, Date, nil]   selected   Date value.
  # @param [String, Symbol, nil] label_id   ID of associated label element.
  # @param [Hash]                opt        Passed to #search_form except for
  #                                           #MENU_OPTS and:
  #
  # @option opt [Date, String]   :selected  Initial value.
  # @option opt [Hash]           :config    Pre-fetched configuration info.
  #
  # @return [ActiveSupport::SafeBuffer]     HTML menu element.
  # @return [nil]                           If menu is not available.
  #
  # @see GridHelper#grid_cell_classes
  #
  def date_control(menu_name, target: nil, selected: nil, label_id: nil, **opt)
    css       = '.date-control'
    target    = search_target(target) or return
    html_opt  = remainder_hash!(opt, :config, :default, *MENU_OPTS)
    config    = opt[:config] || current_menu_config(menu_name, target: target)
    default   = opt.key?(:default) ? opt[:default] : config[:default]
    url_param = (config[:url_param] || menu_name).to_sym

    # Get the initial value for the field.
    value     = selected || request_parameters[url_param] || default

    # Setup the <input> element.
    date_opt  = { 'aria-labelledby': label_id, 'data-default': default }
    input     = date_field_tag(url_param, value, reject_blanks(date_opt))

    # Add CSS classes which indicate the position of the control.
    prepend_grid_cell_classes!(html_opt, css, **opt)
    html_div(html_opt) { input }
  end

  # A label associated with a dropdown menu element.
  #
  # @param [Symbol] menu_name             Control name.
  # @param [Hash]   opt                   Passed to #control_label.
  #
  # @return [ActiveSupport::SafeBuffer]   Empty if no label was configured or
  #                                         provided.
  #--
  # noinspection DuplicatedCode
  #++
  def date_label(menu_name, **opt)
    css = '.date-label'
    append_css!(opt, css)
    control_label(menu_name, **opt)
  end

  # date_tooltip
  #
  # @param [Symbol] menu_name         Control name.
  # @param [Hash]   opt               Passed to #config_tooltip'.
  #
  # @return [String]                  Tooltip text.
  # @return [nil]                     If no tooltip was defined.
  #
  #--
  # noinspection DuplicatedCode
  #++
  def date_tooltip(menu_name, **opt)
    config_tooltip(menu_name, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The control for resetting filter menu selections to their default state.
  #
  # @param [Hash] opt                 Passed to #menu_spacer and #reset_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def reset_menu(**opt)
    # noinspection RubyMismatchedReturnType
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
  # @see GridHelper#grid_cell_classes
  #
  def reset_button(**opt)
    css      = '.menu-button.reset.preserve-width'
    html_opt = remainder_hash!(opt, :url, :class, :label, *MENU_OPTS)
    label    = opt[:label] || SEARCH_RESET_CONTROL[:label]
    label    = non_breaking(label)
    url      = opt[:url] || reset_parameters
    url      = url_for(url) if url.is_a?(Hash)
    html_opt[:title] ||= SEARCH_RESET_CONTROL[:tooltip]
    prepend_grid_cell_classes!(html_opt, css, **opt)
    link_to(label, url, **html_opt)
  end

  # URL parameters that should be cleared for the current search target.
  #
  # @param [Hash] opt                 Default: `#request_parameters`.
  #
  # @return [Hash]
  #
  def reset_parameters(opt = nil)
    opt  ||= request_parameters
    target = search_target(**opt)
    keys   = SEARCH_PARAMETER_MENU_MAP[target]&.keys || []
    keys  -= QUERY_PARAMETERS[target]
    keys  += NON_SEARCH_KEYS
    opt.except(*keys)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A blank element used for occupying "voids" in the search control panel.
  #
  # @param [Hash] opt            Passed to #html_div except for #GRID_OPTS and:
  #
  # @option opt [String] :class       CSS classes for both spacer and button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see GridHelper#grid_cell_classes
  #
  def menu_spacer(**opt)
    css      = '.menu-spacer'
    html_opt = remainder_hash!(opt, :class, *MENU_OPTS)
    html_opt[:'aria-hidden'] = true
    opt.delete(:col_max) # Spacers shouldn't have the 'col-last' CSS class.

    # Add CSS classes which indicate the position of the control.
    prepend_grid_cell_classes!(html_opt, css, **opt)
    html_div(HTML_SPACE, html_opt)
  end

  # A label associated with a dropdown menu element.
  #
  # @param [String, Symbol]      name     Control name.
  # @param [String, Symbol, nil] target   Search target controller.
  # @param [String, nil]         label    Label text override.
  # @param [Hash]                opt      Passed to #label_tag except for
  #                                         #MENU_OPTS and:
  #
  # @option opt [Hash] :config            Pre-fetched configuration info.
  #
  # @return [ActiveSupport::SafeBuffer]   Empty if no label was present.
  #
  # @see GridHelper#grid_cell_classes
  #
  def control_label(name, target: nil, label: nil, **opt)
    css      = '.menu-label'
    html_opt = remainder_hash!(opt, :config, *MENU_OPTS)
    config   = opt[:config] || current_menu_config(name, target: target)
    label  ||= config[:label]
    return ''.html_safe if label.blank?

    # Adjust label appearance.
    if html_opt.delete(:sr_only) || false?(config[:label_visible])
      opt[:sr_only] = true
    else
      label = non_breaking(label)
    end
    opt.delete(:col_max) # Labels shouldn't have the 'col-last' CSS class.

    # Add CSS classes which indicate the position of the control.
    prepend_grid_cell_classes!(html_opt, css, **opt)
    url_param = (config[:url_param] || name).to_sym
    label_tag(url_param, label, html_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Indicate whether the menu is already sorted.
  #
  # @param [Array<Array<(String,Any)>>] menu
  #
  def entries_sorted?(menu)
    sort_entries(menu) == menu
  end

  # Return a sorted copy of the menu.
  #
  # @param [Array<Array<(String,Any)>>] menu
  #
  # @return [Array<Array<(String,Any)>>]
  #
  def sort_entries(menu)
    sort_entries!(menu.dup)
  end

  # Sort the menu by value if the value is a number or by the label otherwise.
  #
  # @param [Array<Array<(String,Any)>>] menu
  #
  # @return [Array<Array<(String,Any)>>]      The possibly-modified *menu*.
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
  # @param [Symbol, String, nil] target     Default: `#search_target`.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see ClassMethods#current_menu_config
  #
  def current_menu_config(menu_name, target: nil, **)
    super(menu_name, target: search_target(target))
  end

  # Get the configured tooltip for the control.
  #
  # @param [String, Symbol] name      Control name.
  # @param [Hash]           opt       Passed to #current_menu_config.
  #
  # @return [String]                  Tooltip text.
  # @return [nil]                     If no tooltip was defined.
  #
  def config_tooltip(name, **opt)
    config = opt[:config] || current_menu_config(name, **opt)
    config&.dig(:tooltip)
  end

end

__loading_end(__FILE__)
