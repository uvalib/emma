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
  def grid_css_class
    "#{model_type}-grid-container"
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

  # Render associated items in a grid based on <table>.
  #
  # @param [Hash] opt                 Passed to #render_grid.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid_table(**opt)
    render_grid(**opt, tag: :table)
  end

  # Render associated items.
  #
  # @param [Integer] row              Starting row number.
  # @param [Integer] index            Starting index number.
  # @param [Array]   cols             Default: `#grid_row_columns`.
  # @param [Symbol]  tag              If :table, generate <table>.
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to container div except
  #                                     #ROW_PAGE_PARAMS to #grid_row_page.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid(row: nil, index: nil, cols: nil, tag: :div, css: nil, **opt)
    css   ||= ".#{grid_row_model_type}-grid"
    row   ||= 0
    index ||= paginator.first_index
    cols  ||= grid_row_columns
    table   = TABLE_TAGS.include?(tag)
    tag     = :table if table

    p_opt   = extract_hash!(opt, *ROW_PAGE_PARAMS)
    items   = grid_row_page(**p_opt)

    r_opt   = { cols: cols, tag: tag }
    head    = render_grid_head_row(row: row, **r_opt)
    rows    = render_grid_data_rows(items, row: (row+1), index: index, **r_opt)

    opt[:role] ||= 'table'
    opt[:'aria-rowcount'] = 1 + grid_row_items_total
    opt[:'aria-colcount'] = 1 + cols.size
    visible_columns       = 1 + visible(cols).size
    prepend_css!(opt, "columns-#{visible_columns}") if table
    prepend_css!(opt, css)
    html_tag(tag, opt) do
      head << rows
    end
  end

  # Generate a header row from field names in the order they are emitted.
  #
  # @param [Array]   cols             Default: `#grid_row_columns`.
  # @param [Integer] row              Starting row number.
  # @param [Symbol]  tag              #TABLE_TAGS
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to outer div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid_head_row(cols: nil, row: nil, tag: :div, css: nil, **opt)
    css ||= ".#{grid_row_model_type}-grid-item"

    headers = grid_head_headers(cols: cols, row: row, tag: tag)

    # The header row is always row 1 regardless of the 'aria-rowindex' of the
    # first data row.
    opt[:'aria-rowindex'] ||= 1

    if TABLE_TAGS.include?(tag)
      html_tag(:thead) do
        prepend_css!(opt, css, "head row-#{row}")
        html_tag(:tr, *headers, opt)
      end
    else
      opt[:role] ||= 'row'
      prepend_css!(opt, css, "head row-#{row} columns-#{headers.size}")
      html_tag(tag, *headers, opt)
    end
  end

  # render_grid_data_rows
  #
  # @param [Array<Model>,nil] items
  # @param [Integer]          row
  # @param [Integer]          index
  # @param [Hash]             opt     Passed to #grid_row.
  #
  # @option opt [Symbol] :tag         Also used by this method.
  # @option opt [Hash]   :outer       Augmented by this method.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grid_data_rows(items = nil, row: nil, index: nil, **opt)
    opt[:cols] ||= grid_row_columns

    items   = items ? Array.wrap(items) : grid_row_page
    index ||= paginator.first_index
    row   ||= 0
    r_min   = row
    r_max   = row + items.size - 1
    outer   = opt.delete(:outer)&.dup || {}
    rows    =
      items.map.with_index do |item, i|
        opt[:row]   = row   + i
        opt[:index] = index + i
        r_class = []
        r_class << 'row-first' if opt[:row] == r_min
        r_class << 'row-last'  if opt[:row] == r_max
        r_outer = r_class.present? ? append_css(outer, *r_class) : outer
        render_grid_data_row(item, **opt, outer: r_outer)
      end
    rows << render_grid_template_row(**opt, outer: outer)

    if TABLE_TAGS.include?(opt[:tag])
      html_tag(:tbody, *rows)
    else
      safe_join(rows, "\n")
    end
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
  def grid_head_control_headers(css: '.controls', **opt, &block)
    opt[:'aria-colindex'] = 1 unless opt.key?(:'aria-colindex')
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
  # @param [Symbol]      tag          #TABLE_TAGS
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          Passed to #html_tag except:
  #
  # @option opt [String] :label       Overrides default label.
  # @option opt [Hash]   :config      Field configuration.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_head_cell(col, row: nil, tag: :div, css: '.cell', **opt, &block)
    table   = TABLE_TAGS.include?(tag)
    tag     = :th if table
    config  = opt.delete(:config) || (field_configuration(col) if col)
    label   = opt.delete(:label)  || config&.dig(:label) || col
    label &&= html_span(label, class: 'label text') unless label.html_safe?
    prop    = config&.slice(:pairs, *FIELD_PROPERTIES)&.compact_blank!
    opt.merge!(prop.transform_keys! { |k| :"data-#{k}" }) if prop.present?
    opt[:role] ||= 'columnheader' if table
    opt[:'data-field'] ||= col
    prepend_css!(opt, "row-#{row}") if row
    prepend_css!(opt, css)
    append_css!(opt, 'undisplayed') if undisplayed?(col)
    html_tag(tag, label, opt, &block)
  end

  # ===========================================================================
  # :section: Methods for individual items
  # ===========================================================================

  public

  # grid_row
  #
  # @param [Hash]    control          Options for #grid_row_controls.
  # @param [String]  unique
  # @param [Symbol]  tag              #TABLE_TAGS
  # @param [Hash]    opt              Passed to #grid_item
  #
  # @option opt [Integer] :row
  # @option opt [Integer] :index
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_row(control: {}, unique: nil, tag: :div, **opt)
    opt[:tag]    = tag
    opt[:index]  = grid_index(opt[:index])
    opt[:unique] = unique || opt[:index]&.value || hex_rand
    col_index    = positive(opt.delete(:'aria-colindex')) || 1
    ctrl_opt     = control.merge(**opt.slice(:unique, :tag))
    controls     = grid_row_controls(**ctrl_opt, 'aria-colindex': col_index)
    grid_item(**opt, leading: controls, 'aria-colindex': col_index.next)
  end

  # Generate controls for an item grid row.
  #
  # @param [Hash]    button           Passed to #grid_row_control_contents.
  # @param [Symbol]  tag              #TABLE_TAGS
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to outer div except:
  #
  # @option opt [String] :unique      Moved into a copy of :button hash.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_row_controls(button: {}, tag: :div, css: '.controls', **opt)
    tag = :th if TABLE_TAGS.include?(tag)
    opt[:role] ||= 'rowheader'
    index  = opt.delete(:index)
    unique = opt.delete(:unique) || index&.value
    button = button.merge(unique: unique) if unique
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
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Additional content if provided.
  # @yieldreturn [Array,ActiveSupport::SafeBuffer,nil]
  #
  def grid_row_control_contents(*added, row: nil, **opt)
    opt.transform_keys! { |k| k.to_s.sub(/^data_/, 'data-').to_sym }
    result = [control_icon_buttons(**opt), *added]
    result = [*result, *yield] if block_given?
    safe_join(result.compact)
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
    opt[:tag]    = :tr  if TABLE_TAGS.include?(opt[:tag])
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
  # @param [Symbol]      tag          #TABLE_TAGS
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
  def grid_data_cell(pairs: nil, separator: nil, tag: :td, css: '.cell', **opt)
    return ''.html_safe if pairs.nil? && object.nil?

    opt.delete(:unique)
    opt.delete(:row)

    opt[:tag]     = tag
    opt[:wrap]    = css_classes(css, opt[:wrap])
    opt[:title]   = ''
    opt[:index] ||= paginator.first_index
    opt[:role]  ||= 'cell'
    separator   ||= DEFAULT_ELEMENT_SEPARATOR
    start         = positive(opt.delete(:'aria-colindex')) || 1
    fp_opt        = extract_hash!(opt, *FIELD_PAIRS_OPTIONS)
    value_opt     = opt.slice(:index, :no_format)
    template      = opt.delete(:template)

    field_pairs(pairs, **fp_opt).map.with_index(start) { |(field, prop), col|
      prop.delete(:required) if template
      label = prop[:label]
      value = render_value(prop[:value], field: field, **value_opt)
      p_opt = { field: field, prop: prop, col: col, **opt }
      append_css!(p_opt, 'undisplayed') if undisplayed?(field)
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
    value = nil if value == EMPTY_VALUE
    unless value.is_a?(Field::Type)
      value = field_for(field, value: value, config: prop)
    end
    opt[:render] ||= :render_grid_input if prop[:type] == 'text'
    opt.merge!(field: field, prop: prop, no_label: true, value_css: css)
    render_form_pair(field, value, **opt)
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
