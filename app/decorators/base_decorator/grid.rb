# app/decorators/base_decorator/grid.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting grid-based displays.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module BaseDecorator::Grid

  include BaseDecorator::Common
  include BaseDecorator::Configuration
  include BaseDecorator::Controls
  include BaseDecorator::Form
  include BaseDecorator::List
  include BaseDecorator::Pagination
  include BaseDecorator::Row

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The collection of items to be presented in grid form.
  #
  # @return [Array<Model>]
  # @return [ActiveRecord::Relation]
  # @return [ActiveRecord::Associations::CollectionAssociation]
  #
  # @see BaseDecorator::Row#row_items
  #
  def grid_row_items
    # noinspection RubyMismatchedReturnType
    row_items
  end

  # The total number of associated items.
  #
  # @return [Integer]
  #
  def grid_row_items_total
    grid_row_items.size
  end

  # The #model_type of individual associated items for iteration.
  #
  # @return [Symbol]
  #
  # @see BaseDecorator::Row#row_model_type
  #
  def grid_row_model_type
    row_model_type
  end

  # The class of individual associated items for iteration.
  #
  # @return [Class]
  #
  def grid_row_model_class
    row_model_class
  end

  # The default CSS class for the container of a grid element.
  #
  # @return [String]
  #
  def grid_container_css_class
    "#{model_type}-grid-container"
  end

  # The default CSS class for a grid element.
  #
  # @return [String]
  #
  def grid_css_class
    "#{grid_row_model_type}-grid"
  end

  # The default CSS class for a grid row element.
  #
  # @return [String]
  #
  def grid_row_css_class
    "#{grid_row_model_type}-grid-item"
  end

  # Indicate whether a grid presents as an element with the HTML 'grid' role.
  #
  def grid_role?
    true
  end

  # The HTML role of the grid element.
  #
  # @param [Boolean] grid
  #
  # @return [String]
  #
  def grid_role(grid: grid_role?)
    grid ? 'grid' : 'table'
  end

  # The HTML role of cells within the grid.
  #
  # @param [Boolean] grid
  #
  # @return [String]
  #
  def grid_cell_role(grid: grid_role?)
    grid ? 'gridcell' : 'cell'
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The names and configurations for each possible grid data column (whether
  # displayed or not).
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def grid_row_fields
    Model.index_fields(grid_row_model_type)
  end

  # The names of each grid data column for display.
  #
  # @return [Array<Symbol>]
  #
  def grid_row_columns
    grid_row_fields.keys - grid_row_skipped_columns
  end

  # The names of each grid data column which is not rendered.
  #
  # @return [Array<Symbol>]
  #
  def grid_row_skipped_columns
    row_skipped_columns
  end

  # The names of each grid data column which is rendered but not visible.
  #
  # @return [Array<Symbol>]
  #
  def grid_row_undisplayed_columns
    []
  end

  # This is the number of <tr> rows within <thead>.
  #
  # @return [Integer]
  #
  def grid_header_rows
    1
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default number of rows per grid page.
  #
  # @type [Integer]
  #
  GRID_PAGE_SIZE = ROW_PAGE_SIZE

  # The number of rows of associated items per grid page.
  #
  # @return [Integer]
  #
  def grid_page_size
    GRID_PAGE_SIZE
  end

  # Get a subset of associated items.
  #
  # @param [Hash] opt                 #ROW_PAGE_PARAMS passed to #row_page.
  #
  # @return [Array<Model>]
  #
  def grid_row_page(**opt)
    opt[:rows]  = grid_row_items unless opt.key?(:rows)
    opt[:limit] = grid_page_size unless opt.key?(:limit)
    row_page(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate grid header/column controls and top/bottom pagination controls.
  #
  # @param [Integer, nil] row
  # @param [Hash]         opt             Passed to #page_content_controls.
  #
  # @return [Array<(ActiveSupport::SafeBuffer,ActiveSupport::SafeBuffer)>]
  #
  def grid_controls(row: nil, **opt)
    opt[:list] ||= grid_row_page(**opt)
    page_content_controls(form_button_tray, row: row, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render associated items.
  #
  # @param [Integer] row              Starting row number.
  # @param [Integer] index            Starting index number.
  # @param [Array]   cols             Default: `#grid_row_columns`.
  # @param [Symbol]  tag              Potential alternative to :table.
  # @param [String]  css              Default: `#grid_css_class`.
  # @param [Hash]    opt              Passed to container div except
  #                                     #ROW_PAGE_PARAMS to #grid_row_page.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid(row: nil, index: nil, cols: nil, tag: nil, css: nil, **opt)
    css   ||= grid_css_class
    row   ||= 0
    index ||= paginator.first_index
    cols  ||= grid_row_columns
    table   = for_html_table?(tag)
    tag     = table && :table || tag || :div
    visible = col_count = row_count = nil
    p_opt   = extract_hash!(opt, *ROW_PAGE_PARAMS)
    parts   = %i[thead tbody tfoot].map { |k| [k, opt.delete(k)] }.to_h.compact

    if parts[:thead].blank?
      r_opt   = { tag: tag, cols: cols, row: row, wrap: false }
      parts[:thead] = render_grid_head_row(**r_opt)
      col_count = 1 + cols.size
      visible   = 1 + visible(cols).size
    end
    row += 1

    if parts[:tbody].blank?
      r_opt = { tag: tag, cols: cols, row: row, index: index, wrap: false }
      parts[:tbody] = render_grid_data_rows(**p_opt, **r_opt)
      row_count     = 1 + grid_row_items_total
    end

    if table
      opt[:role]            ||= grid_role
      opt[:'aria-rowcount'] ||= row_count
      opt[:'aria-colcount'] ||= col_count
      prepend_css!(opt, "columns-#{visible}") if visible
    end

    prepend_css!(opt, css)
    html_tag(tag, opt) do
      if table
        parts.map { |part, content| html_tag(part, content) }
      else
        parts.values
      end
    end
  end

  # Generate a header row from field names in the order they are emitted.
  #
  # @param [Array]   cols             Default: `#grid_row_columns`.
  # @param [Integer] row              Starting row number.
  # @param [Symbol]  tag              Potential alternative to :tr.
  # @param [String]  css              Default: `#grid_row_css_class`.
  # @param [Hash]    opt              Passed to outer div.
  #
  # @option opt [Boolean] :wrap       Specify whether to wrap with :thead.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid_head_row(cols: nil, row: nil, tag: nil, css: nil, **opt)
    css ||= grid_row_css_class
    table = for_html_table?(tag)
    tag   = :tr if table
    wrap  = opt.key?(:wrap) ? opt.delete(:wrap) : table

    # The header row is always row 1 regardless of the 'aria-rowindex' of the
    # first data row.
    opt[:'aria-rowindex'] ||= 1

    headers = grid_head_headers(cols: cols, row: row, tag: tag)
    prepend_css!(opt, "columns-#{headers.size}") unless table
    prepend_css!(opt, css, "head row-#{row}")
    content = html_tag(tag, *headers, opt)
    wrap ? html_tag(:thead, content) : content
  end

  # render_grid_data_rows
  #
  # @param [Array<Model>,nil] items   Default: `#grid_row_page`.
  # @param [Integer]          row
  # @param [Integer]          index
  # @param [Hash]             opt     Passed to #grid_row.
  #
  # @option opt [Boolean] :wrap       Specify whether to wrap with :thead.
  # @option opt [Symbol]  :tag        Also used by this method.
  # @option opt [Hash]    :outer      Augmented by this method.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid_data_rows(items = nil, row: nil, index: nil, **opt)
    table = for_html_table?(opt[:tag])
    wrap  = opt.key?(:wrap) ? opt.delete(:wrap) : table
    opt[:cols] ||= grid_row_columns

    p_opt   = extract_hash!(opt, *ROW_PAGE_PARAMS)

    items   = items ? Array.wrap(items) : grid_row_page(**p_opt)
    index ||= paginator.first_index
    row   ||= 0
    first   = row
    last    = first + items.size - 1
    outer   = opt.delete(:outer)&.dup || {}

    rows =
      items.map.with_index do |item, i|
        opt[:row]   = row   + i
        opt[:index] = index + i
        r_class = []
        r_class << 'row-first' if opt[:row] == first
        r_class << 'row-last'  if opt[:row] == last
        r_outer = r_class.present? ? append_css(outer, *r_class) : outer
        render_grid_data_row(item, **opt, outer: r_outer)
      end
    rows << render_grid_template_row(**opt, outer: outer)

    rows = safe_join(rows, "\n")
    wrap ? html_tag(:tbody, rows) : rows
  end

  # A data row generated by the *item* decorator.
  #
  # @param [Model] item               Provided by the subclass override.
  # @param [Hash]  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid_data_row(item, **opt)
    decorate(item).grid_row(**opt)
  end

  # An additional row -- always hidden -- which can be used as a template for
  # adding a new row.
  #
  # @param [Model, nil] model
  # @param [Hash]       opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid_template_row(model = nil, **opt)
    model      ||= grid_row_model_class.new
    opt[:row]    &&= 0
    opt[:id]       = unique_id(opt[:id])
    opt[:index]    = GridIndex::NONE
    opt[:outer]    = append_css(opt[:outer], 'hidden')
    opt[:template] = true
    # noinspection RubyMismatchedArgumentType
    render_grid_data_row(model, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  CONTROLS_CELL_CLASS = 'controls-cell'

  # Properties that need to be conveyed to the grid header columns.
  #
  # @type [Array<Symbol>]
  #
  FIELD_PROPERTIES = [:max, :min, :role, *Field::SYNTHETIC_KEYS].freeze

  # grid_head_headers
  #
  # @param [Hash] **opt
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def grid_head_headers(**opt)
    i = positive(opt[:'aria-colindex']) || 1
    c = grid_head_control_headers(**opt.slice(:row, :tag), 'aria-colindex': i)
    d = grid_head_data_headers(**opt, 'aria-colindex': i.next)
    [*c, *d]
  end

  # Render the control column header (the top left grid cell).
  #
  # By default this is just a spacer for the control column.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #grid_head_cell.
  # @param [Proc]   block             Passed to #grid_head_cell.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def grid_head_control_headers(css: CONTROLS_CELL_CLASS, **opt, &block)
    idx   = opt[:'aria-colindex'] ||= 1
    l_id  = opt[:'aria-labelledby'] = unique_id(css, index: idx)
    label = 'Row controls' # TODO: I18n
    opt[:label] = grid_head_label(label, id: l_id, class: 'sr-only')
    [grid_head_cell(nil, css: css, **opt, &block)]
  end

  # Render data column headers.
  #
  # @param [Array] cols               Default: `#grid_row_columns`.
  # @param [Hash]  opt                Passed to #grid_head_cell.
  # @param [Proc]  block              Passed to #grid_head_cell.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def grid_head_data_headers(cols: nil, **opt, &block)
    start_column = positive(opt.delete(:'aria-colindex')) || 1
    (cols || grid_row_columns).map.with_index(start_column) do |col, idx|
      grid_head_cell(col, **opt, 'aria-colindex': idx, &block)
    end
  end

  # Render a grid header cell.
  #
  # @param [Symbol, nil] col          Data column.
  # @param [Integer]     row          Starting row.
  # @param [Symbol]      tag          Potential alternative to :th.
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          Passed to #html_tag except:
  #
  # @option opt [String] :label       Overrides default label.
  # @option opt [Hash]   :config      Field configuration.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_head_cell(col, row: nil, tag: nil, css: '.cell', **opt, &block)
    table   = for_html_table?(tag)
    tag     = :th if table
    hidden  = undisplayed?(col)
    config  = opt.delete(:config) || (field_configuration(col) if col)
    label   = opt.delete(:label)  || config&.dig(:label) || col.to_s
    unless label.html_safe?
      idx   = opt[:'aria-colindex']
      l_id  = opt[:'aria-labelledby'] = unique_id(css, index: idx)
      label = grid_head_label(label, id: l_id)
    end
    prop    = config&.slice(:pairs, *FIELD_PROPERTIES)&.compact_blank!
    opt.merge!(prop.transform_keys! { |k| :"data-#{k}" }) if prop.present?
    opt[:role]           = 'columnheader' if table
    opt[:'aria-hidden']  = true           if hidden
    opt[:'data-field'] ||= col
    append_css!(opt, 'undisplayed')       if hidden
    prepend_css!(opt, "row-#{row}")       if row
    prepend_css!(opt, css)
    html_tag(tag, label, opt, &block)
  end

  # Render a grid header cell label element.
  #
  # @param [String, nil] text
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_head_label(text = nil, css: '.label.text', **opt)
    text ||= yield
    prepend_css!(opt, css)
    html_span(text, opt)
  end

  # ===========================================================================
  # :section: Methods for individual items
  # ===========================================================================

  public

  # grid_row
  #
  # @param [Hash]    control          Options for #grid_row_controls.
  # @param [String]  unique
  # @param [Symbol]  tag              Potential alternative to :tr.
  # @param [Hash]    opt              Passed to #grid_item
  #
  # @option opt [Integer] :row
  # @option opt [Integer] :index
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_row(control: {}, unique: nil, tag: nil, **opt)
    opt[:tag]    = for_html_table?(tag) ? :tr : tag
    opt[:index]  = grid_index(opt[:index])
    opt[:unique] = unique || opt[:index]&.value || hex_rand
    col_index    = positive(opt.delete(:'aria-colindex')) || 1
    ctrl_opt     = opt.slice(:tag, :unique).reverse_merge!(control)
    controls     = grid_row_controls(**ctrl_opt, 'aria-colindex': col_index)
    grid_item(**opt, leading: controls, 'aria-colindex': col_index.next)
  end

  # Generate controls for an item grid row.
  #
  # @param [Hash]    button           Passed to #grid_row_control_contents.
  # @param [Symbol]  tag              Potential alternative to :th.
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to outer div except:
  #
  # @option opt [String] :unique      Moved into a copy of :button hash.
  # @option opt [String] :label       Screen-reader label for container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_row_controls(button: {}, tag: nil, css: CONTROLS_CELL_CLASS, **opt)
    table  = for_html_table?(tag)
    tag    = :th if table

    index  = opt.delete(:index)
    unique = opt.delete(:unique) || index&.value
    button = unique ? button.merge(unique: unique) : button.dup
    row    = opt[:'aria-rowindex']
    l_id   = opt[:'aria-labelledby'] = unique_id(css, index: row)
    label  = opt.delete(:label) || button[:label] || 'Controls for row %{row}' # TODO: I18n
    label  = label % { row: row } if row && label.include?('%{row}')
    unless label.html_safe?
      label = grid_head_label(label, id: l_id, class: 'sr-only')
    end
    button.merge!(label: label, 'aria-labelledby': l_id)

    opt[:role] = 'rowheader' if table
    prepend_css!(opt, css)
    html_tag(tag, opt) do
      grid_row_control_contents(**button)
    end
  end

  # Generate the interior of the controls grid cell.
  #
  # @param [Array]   added            Optional elements after the buttons.
  # @param [Integer] row              Associated grid row.
  # @param [Hash]    opt              Passed to #control_icon_buttons.
  #
  # @option opt [String] :label       Screen-reader label for container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Additional content if provided.
  # @yieldreturn [Array,ActiveSupport::SafeBuffer,nil]
  #
  def grid_row_control_contents(*added, row: nil, **opt)
    opt.transform_keys! { |k| k.to_s.sub(/^data_/, 'data-').to_sym }
    l_id  = opt.delete(:'aria-labelledby')
    label = opt.delete(:label)
    ctrls = control_icon_buttons(**opt)
    ctrls = [ctrls, *added, *(yield if block_given?)]
    ctrls = control_group(l_id) { ctrls }
    safe_join([label, ctrls].compact)
  end

  # Render a single grid item.
  #
  # @param [Array] cols               Default: `#grid_row_columns`.
  # @param [Hash]  opt                @see BaseDecorator::List#list_item
  #
  # @option opt [Symbol] :tag         Set for #list_item if required.
  # @option opt [String] :unique
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_item(cols: nil, **opt)
    cols = nil unless cols&.difference(grid_row_columns)&.present?
    opt[:css]    = ".#{model_type}-grid-item" unless opt.key?(:css)
    opt[:tag]    = :tr  if for_html_table?(opt[:tag])
    opt[:only]   = cols if cols
    opt[:except] = grid_row_skipped_columns unless cols
    opt[:index]  = grid_index(opt[:index])
    opt[:outer]  = opt[:outer]&.except(:unique) || {}
    opt[:outer].merge!(role: 'row', 'aria-rowindex': (opt[:index] + 1))
    opt[:render] = :grid_data_cell
    list_item(**opt)
  end

  # Render a grid data cell with value display element and an edit element.
  #
  # @param [Hash, nil]   pairs        Passed to #field_pairs.
  # @param [String, nil] separator    Default: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Symbol]      tag          Potential alternative to :td.
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          To #render_pair except
  #                                     #FIELD_PAIRS_OPTIONS to #field_pairs.
  #
  # @option opt [Integer] :index      Offset to make unique element IDs passed
  #                                     to #render_pair.
  # @option opt [*]       :row        Deleted to avoid propagation so that
  #                                     individual elements don't have CSS
  #                                     class "row-*".
  # @option opt [*]       :unique     Deleted to avoid propagation.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_data_cell(pairs: nil, separator: nil, tag: nil, css: '.cell', **opt)
    return ''.html_safe if pairs.nil? && object.nil?

    opt.delete(:unique)
    opt.delete(:title)
    opt.delete(:row)

    table         = for_html_table?(tag)
    opt[:tag]     = :td            if table
    opt[:role]    = grid_cell_role if table
    opt[:wrap]    = css_classes(css, opt[:wrap])
    opt[:index] ||= paginator.first_index
    separator   ||= DEFAULT_ELEMENT_SEPARATOR
    start         = positive(opt.delete(:'aria-colindex')) || 1
    fp_opt        = extract_hash!(opt, *FIELD_PAIRS_OPTIONS)
    value_opt     = opt.slice(:index, :no_format)
    template      = opt.delete(:template)

    field_pairs(pairs, **fp_opt).map.with_index(start) { |(field, prop), col|
      prop.delete(:required) if template
      hidden = undisplayed?(field)
      label  = prop[:label]
      value  = render_value(prop[:value], field: field, **value_opt)
      p_opt  = { **opt, field: field, prop: prop, col: col }
      p_opt[:'aria-hidden'] = true      if hidden
      append_css!(p_opt, 'undisplayed') if hidden
      grid_data_cell_render_pair(label, value, **p_opt)
    }.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair in a grid cell.
  #
  # @param [String, Symbol, nil] label
  # @param [*]                   value
  # @param [Symbol]              field
  # @param [Hash]                prop
  # @param [Integer, nil]        col
  # @param [Hash]                opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Implementation Notes
  # Compare with BaseDecorator::List#render_field_value_pair
  #
  def grid_data_cell_render_pair(label, value, field:, prop:, col: nil, **opt)
    # Special adjustment to keep #render_pair from causing single-select values
    # from being represented as multi-select inputs.
    prop[:array] ||= :false if prop[:type].is_a?(Class)
    rp_opt = opt.merge(field: field, prop: prop, 'aria-colindex': col)
    scopes = field_scopes(field).presence and append_css!(rp_opt, *scopes)
    rp_opt.merge!(no_format: true, no_help: true)
    render_pair(label, value, **rp_opt) do |fld, val, prp, **cell_opt|
      grid_data_cell_edit(fld, val, prp, **cell_opt, **opt.slice(:index))
    end
  end

  # The edit element for a grid data cell.
  #
  # @param [Symbol]    field          For 'data-field' attribute.
  # @param [*]         value
  # @param [Hash, nil] prop           Default: from field/model.
  # @param [String]    css            Characteristic CSS class/selector.
  # @param [Hash]      opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def grid_data_cell_edit(field, value, prop, css: '.edit', **opt)
    id_opt = opt.slice(:index).merge!(field: field)
    l_id   = field_html_id("edit-#{DEFAULT_LABEL_CLASS}", **id_opt)
    value  = nil if value == EMPTY_VALUE
    unless value.is_a?(Field::Type)
      value = field_for(field, value: value, config: prop)
    end

    opt[:field]     = field
    opt[:prop]      = prop
    opt[:label_id]  = l_id
    opt[:label_css] = "#{DEFAULT_LABEL_CLASS} sr-only"
    opt[:value_css] = css
    opt[:render]  ||= :render_grid_input if prop[:type] == 'text'

    control_group(l_id) do
      render_form_pair(field, value, **opt)
    end
  end

  # ===========================================================================
  # :section: Methods for individual items
  # ===========================================================================

  protected

  # Indicate whether the field is one whose elements should be invisible.
  #
  # @param [*] field
  #
  def undisplayed?(field)
    grid_row_undisplayed_columns.include?(field)
  end

  # Return the fields which contribute to the count of visible grid columns.
  #
  # @param [Array<Symbol>, Symbol] fields
  #
  # @return [Array<Symbol>]
  #
  def visible(fields)
    Array.wrap(fields).reject { |field| undisplayed?(field) }
  end

  # Create an object that can be used to unambiguously indicate whether an
  # index value has been adjusted from its original raw value.
  #
  # @param [GridIndex, Symbol, Integer, String, nil] item
  #
  # @return [GridIndex, nil]
  #
  def grid_index(item)
    # noinspection RubyMismatchedReturnType
    return item if item.is_a?(GridIndex)
    GridIndex.new(item, grid_header_rows) unless item.blank?
  end

  # This is a special variation which causes a <textarea> to be created for
  # retrieving single text strings instead of <input type="text">.
  #
  # (This is the only way to cause the placeholder text to be wrapped in the
  # grid cell.  For a simple input, the width of the <input> placeholder does
  # not contribute to the width of the invisible edit element, so the grid
  # column does not get created wide enough to see the whole placeholder text.)
  #
  # @param [String] name
  # @param [*]      value
  # @param [Hash]   opt               Passed to #render_form_input.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid_input(name, value, **opt)
    render_form_input(name, value, **opt, type: :textarea)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  class GridIndex

    NONE = :none

    # @return [Integer]
    attr_reader :base

    # @return [Integer]
    attr_reader :offset

    # @return [Boolean]
    attr_reader :none

    # Create a new instance.
    #
    # @param [GridIndex, Symbol, String, Integer, nil] item
    # @param [Integer, nil]                            starting_offset
    #
    def initialize(item, starting_offset = nil)
      if (@none = (item == NONE))
        @base, @offset = 0, 0
      elsif item.is_a?(GridIndex)
        Log.warn('GridIndex: starting_offset ignored') if starting_offset
        @base, @offset = item.base, item.offset
      else
        @base, @offset = item.to_i, starting_offset.to_i
      end
    end

    # @return [Integer]
    def value
      base + offset
    end

    alias to_i value

    # @return [String]
    def to_s
      value.to_s
    end

    # @return [GridIndex]
    def +(increment)
      if none || (increment == NONE) || increment.try(:none)
        dup
      else
        GridIndex.new((base + increment.to_i), offset)
      end
    end

    # @return [GridIndex]
    # @return [nil]                   If `#none` is true.
    def next
      GridIndex.new(base.next, offset) unless none
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
