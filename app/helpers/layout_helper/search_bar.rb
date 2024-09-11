# app/helpers/layout_helper/search_bar.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the '<header>' search bar.
#
module LayoutHelper::SearchBar

  include LayoutHelper::SearchFilters

  include ConfigurationHelper
  include LinkHelper
  include ParamsHelper
  include SearchTermsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A table of search bar behavior for each controller.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_BAR =
    ApplicationHelper::APP_CONTROLLERS.map { |controller|
      opt   = { controller: controller, mode: false }
      entry = config_lookup('search_bar', **opt) || {}
      enabled, min_rows, max_rows =
        entry.values_at(:enabled, :min_rows, :max_rows)
      enabled  = enabled.is_a?(Array) ? enabled.map(&:to_s) : !false?(enabled)
      min_rows = positive(min_rows)
      max_rows = positive(max_rows)
      if min_rows && max_rows
        min_rows = max_rows if min_rows > max_rows
      elsif min_rows
        max_rows = min_rows unless entry.key?(:max_rows)
      else
        min_rows = (max_rows ||= 1)
      end
      entry.merge!(enabled: enabled, min_rows: min_rows, max_rows: max_rows)
      [controller, entry]
    }.to_h.deep_freeze

  # The icon used within the search bar to clear the current search.
  #
  # @type [String]
  #
  CLEAR_SEARCH_ICON = HEAVY_X

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the search bar.
  #
  # @param [Symbol, String, nil] ctrlr  Default: params[:controller].
  # @param [Hash, nil]           opt    Default: `#request_parameters`.
  #
  def show_search_bar?(ctrlr = nil, opt = nil)
    ctrlr, opt = [nil, ctrlr] if ctrlr.is_a?(Hash)
    opt = opt&.symbolize_keys || request_parameters
    ctrlr ||= opt.values_at(:controller, :target).first
    enabled = SEARCH_BAR.dig(ctrlr&.to_sym, :enabled)
    enabled = enabled.include?(opt[:action].to_s) if enabled.is_a?(Array)
    enabled.present?
  end

  # Indicate whether it is appropriate to show the search input menu.
  #
  # @param [Symbol, String, nil] ctrlr  Passed to #search_input_types.
  # @param [Hash]                opt    Passed to #search_input_types.
  #
  def show_input_select?(ctrlr = nil, **opt)
    search_input_types(ctrlr, **opt).size > 1
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # search_bar_container
  #
  # @param [Symbol, String, nil]   target     Default: `#search_input_target`
  # @param [Array, Hash, nil]      fields     Default: `#search_input_types`.
  # @param [Hash, nil]             values     Default: `#url_parameters`.
  # @param [Symbol, Array<Symbol>] only
  # @param [Symbol, Array<Symbol>] except
  # @param [Integer, nil]          maximum    Maximum input rows in group.
  # @param [Integer, nil]          minimum    Minimum input rows in group.
  # @param [String, nil]           unique
  # @param [String]                css        Characteristic CSS class/selector
  # @param [Hash]                  form_opt   Passed to #html_form.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                             Search unavailable for *target*.
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def search_bar_container(
    target:   nil,
    fields:   nil,
    values:   nil,
    only:     nil,
    except:   nil,
    maximum:  nil,
    minimum:  nil,
    unique:   nil,
    css:      '.search-bar-container',
    **form_opt
  )
    target   = search_input_target(target) or return
    config   = SEARCH_BAR[(target || params[:controller])&.to_sym]
    minimum  = minimum ? [minimum, 1].max : config[:min_rows]
    maximum  = maximum ? [maximum, 1].max : config[:max_rows]
    types    = search_input_types(target)
    prm_map  =
      types.map { |type, cfg|
        prm = cfg[:url_param]&.to_sym || type
        [prm, type]
      }.to_h

    # A search box row will be created for every search type.
    fields ||= types
    fields   = fields.keys if fields.is_a?(Hash)
    fields   = filter(fields, only: only, except: except)

    # Accumulate search term values limited to the selected set of fields.
    # The initial determination of the order and initial input type selections
    # will be determined by the data supplied.
    values = values&.symbolize_keys || url_parameters
    values.except!(*Paginator::NON_SEARCH_KEYS)
    values.transform_keys! { prm_map[_1] }
    values.slice!(*fields)
    values.transform_values! { (_1 == SearchTerm::NULL_SEARCH) ? '' : _1 }

    # This is a major section of the page so it should be present in the
    # skip menu.
    unique ||= hex_rand
    row_opt  = { target: target, unique: unique }
    form_opt[:id] ||= unique_id('search', **row_opt)
    skip_nav_append(search_bar_label(target) => form_opt[:id])

    # Search input row elements.
    blank = fields - values.keys
    rows  = values.merge!(blank.map { [_1, ''] }.to_h).to_a
    if maximum && (rows.size > maximum)
      rows = rows.take(maximum)
    elsif minimum
      rows << [fields.first, ''] while rows.size < minimum
    end
    row = 0
    rows.map! do |field, value|
      row_opt[:first] = row.zero?
      row_opt[:index] = (row += 1)
      row_opt[:last]  = (row == rows.size)
      search_bar_row(field, value, **row_opt)
    end

    # Components.
    input_group = html_div(rows, class: 'search-bar-group', role: 'group')
    controls    = ''.html_safe # NOTE: moving search button...

    prepend_css!(form_opt, css)
    search_form(target, **form_opt) do
      input_group << controls
    end
  end

  # Generate a row within a search-bar-group.
  #
  # @param [Symbol, String, nil] field      Passed to #search_input.
  # @param [String, nil]         value      Passed to #search_input.
  # @param [Boolean, nil]        first      If *true* this is the first row.
  # @param [Boolean, nil]        last       If *true* this is the last row.
  # @param [Hash]                opt        Passed to outer #html_div except:
  #
  # @option opt [String, Symbol]  :target
  # @option opt [String, Boolean] :unique   Passed to #unique_id.
  # @option opt [Integer]         :index    Passed to #unique_id.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_bar_row(field, value = nil, first: nil, last: nil, **opt)
    css    = '.search-bar-row'
    id_opt = opt.extract!(:target, :unique, :index)

    # Row elements.
    input  = search_bar(field, value, **id_opt)
    menu   = search_input_select(selected: field, **id_opt)
    ctrl   = menu.presence
    ctrl &&= first ? search_row_add(**id_opt) : search_row_remove(**id_opt)

    # Row container.
    opt[:id]   ||= unique_id(css, **id_opt)
    opt[:role] ||= 'group'
    prepend_css!(opt, css)
    append_css!(opt, 'first')  if first
    append_css!(opt, 'last')   if last
    append_css!(opt, 'hidden') unless first || value.present?
    html_div(**opt) do
      [menu, input, ctrl].compact
    end
  end

  # Reveal the next search-bar-row in the current search-bar-group.
  #
  # @param [Hash] opt                 Passed to #search_row_control.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_row_add(**opt)
    opt[:title] ||= config_term(:search_bar, :row_add, :tooltip)
    opt[:icon]  ||= HEAVY_PLUS
    search_row_control('add', **opt)
  end

  # Reveal the associated search-bar-row.
  #
  # @param [Hash] opt                 Passed to #search_row_control.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_row_remove(**opt)
    opt[:title] ||= config_term(:search_bar, :row_remove, :tooltip)
    opt[:icon]  ||= HEAVY_MINUS
    search_row_control('remove', **opt)
  end

  # Generate an element for selecting search type.
  #
  # @param [String] css                     Characteristic CSS class/selector.
  # @param [Hash]   opt                     Passed to #select_tag except for
  #                                           #MENU_OPT and:
  #
  # @option opt [String, Symbol]  :target
  # @option opt [String, Boolean] :unique   Passed to #unique_id.
  # @option opt [Integer]         :index    Passed to #unique_id.
  #
  # @return [ActiveSupport::SafeBuffer]     An HTML input element.
  # @return [nil]                           Search unavailable for target.
  #
  def search_input_select(css: '.search-input-select', **opt)
    target = search_input_target(opt.delete(:target))
    return unless target && show_input_select?(target)

    pairs    = search_query_menu_pairs(target)
    selected = Array.wrap(opt.delete(:selected)).map(&:to_s).uniq
    option_tags = options_for_select(pairs, selected)

    id_opt = opt.extract!(:unique, :index)
    opt.except!(:field, *MENU_OPT)

    prepend_css!(opt, css)
    opt[:id]           ||= unique_id(css, **id_opt) if id_opt.present?
    opt[:title]        ||= config_term(:search_bar, :input_select, :tooltip)
    opt[:'aria-label'] ||= opt[:title]
    # NOTE: Blank name so that it is not included with form submission data.
    select_tag('', option_tags, opt)
  end

  # Generate an element for entering search terms.
  #
  # @param [Symbol, String, nil] field
  # @param [String, nil]         value
  # @param [String]              css        Characteristic CSS class/selector.
  # @param [Hash]                opt        Passed to #html_div except for:
  #
  # @option opt [String, Symbol]  :target
  # @option opt [String, Boolean] :unique   Passed to #unique_id.
  # @option opt [Integer]         :index    Passed to #unique_id.
  #
  # @return [ActiveSupport::SafeBuffer]     An HTML input element.
  # @return [nil]                           Search unavailable for target.
  #
  def search_bar(field, value = nil, css: '.search-bar', **opt)
    id_opt = opt.extract!(:target, :unique, :index)
    target = id_opt[:target] ||= search_input_target
    return unless target && show_search_bar?(target)
    prepend_css!(opt, css)
    html_div(**opt) do
      search_input(field, value: value, **id_opt)
    end
  end

  # search_bar_label
  #
  # @param [Symbol, String, nil] ctrlr    Default: *target*
  # @param [Symbol, String, nil] target   Default: `#search_input_target`
  # @param [Hash]                opt      Passed to #config_lookup.
  #
  # @return [String]                      The specified value.
  # @return [nil]                         No non-empty value was found.
  #
  def search_bar_label(ctrlr = nil, target: nil, **opt)
    target = search_input_target(ctrlr || target) or return
    config_lookup('search_bar.label', controller: target, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # An operation on a search-bar-row.
  #
  # @param [String, Symbol] operation
  # @param [String]         css             Characteristic CSS class/selector.
  # @param [Hash]           opt             Passed to #icon_button except for:
  #
  # @option opt [any, nil]        :field    Discarded.
  # @option opt [any, nil]        :target   Discarded.
  # @option opt [String, Boolean] :unique   Passed to #unique_id.
  # @option opt [Integer]         :index    Passed to #unique_id.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_row_control(operation, css: '.search-row-control', **opt)
    css = "#{css}.#{operation}"
    opt.except!(:field, :target)
    id_opt     = opt.extract!(:unique, :index)
    opt[:id] ||= unique_id(css, **id_opt)
    prepend_css!(opt, css)
    icon_button(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL parameter to which search terms should be applied.
  #
  # @param [Symbol, String, nil] ctrlr  Default: `#search_input_target`
  # @param [Hash]                opt    Passed to #search_input_type.
  #
  # @return [Symbol]                    The specified value.
  # @return [nil]                       No non-empty value was found.
  #
  def search_input_field(ctrlr = nil, **opt)
    # noinspection RubyMismatchedReturnType
    opt[:field]&.to_sym || search_input_type(ctrlr, **opt)[:field]
  end

  # Screen-reader-only label for the input field.
  #
  # @param [Symbol, String, nil] ctrlr  Passed to #search_input_type.
  # @param [Hash]                opt    Passed to #search_input_type.
  #
  # @return [String]                    The specified value.
  # @return [nil]                       No non-empty value was found.
  #
  def search_input_label(ctrlr = nil, **opt)
    # noinspection RubyMismatchedReturnType
    search_input_type(ctrlr, **opt)[:label]
  end

  # Placeholder text displayed in the search input box.
  #
  # @param [Symbol, String, nil] ctrlr  Passed to #search_input_type.
  # @param [Hash]                opt    Passed to #search_input_type.
  #
  # @return [String]                    The specified value.
  # @return [nil]                       No non-empty value was found.
  #
  def search_input_placeholder(ctrlr = nil, **opt)
    # noinspection RubyMismatchedReturnType
    search_input_type(ctrlr, **opt)[:placeholder]
  end

  # Properties of the indicated search input type.
  #
  # @param [Symbol, String, nil] ctrlr    Default: `#search_input_types`
  # @param [Symbol, String, nil] target   Default: `#search_input_types`
  # @param [Symbol, String, nil] field    Input type; first one if not given.
  # @param [Hash]                opt      Passed to #search_input_types.
  #
  # @return [Hash{Symbol=>Symbol,String}]
  #
  def search_input_type(ctrlr = nil, target: nil, field: nil, **opt)
    config = search_input_types(ctrlr, target: target, **opt)
    if (field = field&.to_sym)
      values = config[field]
    else
      field, values = config.first # Assume first type is the default type.
    end
    values ? { field: field }.merge!(values) : {}
  end

  # All defined input types.
  #
  # @param [Symbol, String, nil] ctrlr    Default: *target*
  # @param [Symbol, String, nil] target   Default: `#search_input_target`
  # @param [Hash]                opt      Passed to #config_lookup.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def search_input_types(ctrlr = nil, target: nil, **opt)
    ctrlr = search_input_target(ctrlr || target)
    config_lookup('search_type', controller: ctrlr, **opt) || {}
  end

  # search_input_target
  #
  # @param [Symbol, String, nil] ctrlr    Default: *target*
  # @param [Symbol, String, nil] target   Default: `#search_target`
  #
  # @return [Symbol]                      The controller used for searching.
  # @return [nil]                         If search input should not be enabled
  #
  def search_input_target(ctrlr = nil, target: nil, **)
    ctrlr = search_target(ctrlr || target)
    # noinspection RubyMismatchedReturnType
    ctrlr if SEARCH_BAR.dig(ctrlr, :enabled)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a form search field input control.
  #
  # @param [Symbol, String, nil] field      Default: `#search_input_field`.
  # @param [Symbol, String, nil] ctrlr      Default: *target*.
  # @param [Symbol, String, nil] target     Default: `#search_input_target`.
  # @param [String, nil]         value      Default: `params[*field*]`.
  # @param [String]              css        Characteristic CSS class/selector.
  # @param [Hash]                opt        Passed to #search_field_tag except:
  #
  # @option opt [String, Boolean] :unique   Passed to #unique_id.
  # @option opt [Integer]         :index    Passed to #unique_id.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @note Used by UploadDecorator#parent_entry_select
  #
  def search_input(
    field,
    ctrlr = nil,
    target: nil,
    value:  nil,
    css:    '.search-input',
    **opt
  )
    target   = search_input_target(ctrlr, target: target)
    field  ||= search_input_field(target)
    field    = field&.to_sym
    id_opt   = opt.extract!(:unique, :index).presence

    # Screen-reader-only label element (if required).
    label    = nil
    label_id = opt[:'aria-labelledby']
    if label_id.nil? && (label = search_input_label(target, field: field))
      label_id = opt[:'aria-labelledby'] =
        id_opt ? unique_id(css, 'label', **id_opt) : "#{field}-label"
      label = html_span(label, id: label_id, class: 'search-input-label')
    end
    label ||= ''.html_safe

    # Input field contents.
    value ||= request_parameters[field]
    value   = '' if value == SearchTerm::NULL_SEARCH

    # Input field element.
    prepend_css!(opt, css)
    opt[:id]          ||= id_opt ? unique_id(css, **id_opt) : field
    opt[:placeholder] ||= search_input_placeholder(target, field: field)
    input = search_field_tag(field, value, opt)

    # Control for clearing search terms.
    clear = search_clear_button(**id_opt.to_h)

    # Result.
    label << input << clear
  end

  SEARCH_READY_TOOLTIP =
    config_term(:search_bar, :search_button, :ready, :tooltip).freeze

  SEARCH_NOT_READY_TOOLTIP =
    config_term(:search_bar, :search_button, :not_ready, :tooltip).freeze

  # Generate a form submit control.
  #
  # @param [Symbol, String, nil] ctrlr    Default: *target*
  # @param [Symbol, String, nil] target   Default: `#search_input_target`
  # @param [String, nil]         label    Default: `#search_button_label`.
  # @param [String]              css      Characteristic CSS class/selector.
  # @param [Hash]                opt      Passed to #submit_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_button(
    ctrlr = nil,
    target: nil,
    label:  nil,
    css:    '.search-button',
    **opt
  )
    label ||= search_button_label(ctrlr || target)
    opt[:'data-ready']     ||= SEARCH_READY_TOOLTIP
    opt[:'data-not-ready'] ||= SEARCH_NOT_READY_TOOLTIP
    prepend_css!(opt, css)
    submit_tag(label, opt)
  end

  # search_button_label
  #
  # @param [Symbol, String, nil] ctrlr    Default: *target*
  # @param [Symbol, String, nil] target   Default: `#search_input_target`
  # @param [Hash]                opt      Passed to #config_lookup.
  #
  # @return [String]                      The specified value.
  # @return [nil]                         No non-empty value was found.
  #
  # @note Used by UploadDecorator#parent_entry_select
  #
  def search_button_label(ctrlr = nil, target: nil, **opt)
    target = search_input_target(ctrlr || target) or return
    config_lookup('search_bar.button.label', controller: target, **opt)
  end

  # search_clear_button
  #
  # @param [String] css                     Characteristic CSS class/selector.
  # @param [Hash]   opt                     Passed to #icon_button except for:
  #
  # @option opt [String, Boolean] :unique   Passed to #unique_id.
  # @option opt [Integer]         :index    Passed to #unique_id.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/feature/advanced-search.js *clearSearchTerm()*
  #
  def search_clear_button(css: '.search-clear', **opt)
    id_opt = opt.extract!(:unique, :index)
    opt.except!(:field, *MENU_OPT)
    prepend_css!(opt, css)
    opt[:title] ||= config_term(:search_bar, :search_clear, :tooltip)
    opt[:icon]  ||= CLEAR_SEARCH_ICON
    opt[:url]   ||= '#'
    opt[:id]    ||= unique_id(css, **id_opt)
    icon_button(**opt)
  end

  SEARCH_CONTROLS = %i[reset search toggle].freeze

  # A container for the search submit, filter reset, and filter toggle buttons.
  #
  # @param [Symbol, String, nil]   ctrlr    Default: *target*
  # @param [Symbol, String, nil]   target   Default: `#search_button`
  # @param [String, nil]           form     Form element identifier.
  # @param [String]                css      Characteristic CSS class/selector.
  # @param [Hash]                  opt      Passed to #html_div except:
  #
  # @option opt [Symbol, Array<Symbol>] :only     One or more #SEARCH_CONTROLS.
  # @option opt [Symbol, Array<Symbol>] :except   One or more #SEARCH_CONTROLS.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_controls(
    ctrlr = nil,
    target: nil,
    form:   nil,
    css:    '.search-controls',
    **opt
  )
    target  = search_input_target(ctrlr, target: target)
    f_opt   = opt.extract!(:only, :except)
    buttons = filter(SEARCH_CONTROLS, **f_opt)
    prepend_css!(opt, css)
    html_div(**opt) do
      buttons.map do |key|
        case key
          when :toggle then advanced_search_button
          when :reset  then reset_button
          when :search then search_button(target, form: form)
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Filter values from an array.
  #
  # @param [Array<Symbol>, Symbol, nil] obj
  # @param [Array<Symbol>, Symbol, nil] only
  # @param [Array<Symbol>, Symbol, nil] except
  #
  # @return [Array]                   A modified copy of *obj*.
  #
  def filter(obj, only: nil, except: nil, **)
    array = Array.wrap(obj).compact.map!(&:to_sym)
    filter!(array, only: only, except: except)
  end

  # Filter values from an array.
  #
  # @param [Array<Symbol>]              array
  # @param [Array<Symbol>, Symbol, nil] only
  # @param [Array<Symbol>, Symbol, nil] except
  #
  # @return [Array]                   The original object, possibly modified.
  #
  def filter!(array, only: nil, except: nil, **)
    only   &&= Array.wrap(only).compact.presence&.map!(&:to_sym)
    except &&= Array.wrap(except).compact.presence&.map!(&:to_sym)
    array.keep(*only)     if only
    array.remove(*except) if except
    array
  end

end

__loading_end(__FILE__)
