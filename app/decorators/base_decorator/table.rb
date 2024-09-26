# app/decorators/base_decorator/table.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting tabular display of Model instances.
#
module BaseDecorator::Table

  include BaseDecorator::Common
  include BaseDecorator::List
  include BaseDecorator::Row

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Make the heading row stick to the top of the table when scrolling.
  #
  # @type [Boolean]
  #
  # @see file:stylesheets/layouts/controls/_tables.scss "CSS class head-sticky"
  #
  TABLE_HEAD_STICKY = true?(ENV_VAR['TABLE_HEAD_STICKY'])

  # Give the heading row a background.
  #
  # @type [Boolean]
  #
  # @see file:stylesheets/layouts/controls/_tables.scss "CSS class head-dark"
  #
  TABLE_HEAD_DARK = true?(ENV_VAR['TABLE_HEAD_DARK'])

  # Options used by some or all of the methods involved in rendering items in
  # a tabular form.
  #
  # @type [Array<Symbol>]
  #
  MODEL_TABLE_OPT = [
    :model,
    MODEL_TABLE_DATA_OPT  = %i[partial pageable sortable].freeze,
    MODEL_TABLE_HEAD_OPT  = %i[sticky dark].freeze,
    MODEL_TABLE_ENTRY_OPT = %i[outer_tag inner_tag].freeze,
    MODEL_TABLE_ROW_OPT   = %i[row col].freeze,
    MODEL_TABLE_PART_OPT  = %i[thead tbody tfoot].freeze,
  ].flatten.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The collection of items to be presented in tabular form.
  #
  # @param [Hash] opt                 Modifies *object* results.
  #
  # @return [Array<Model>]
  # @return [ActiveRecord::Relation]
  # @return [ActiveRecord::Associations::CollectionAssociation]
  #
  def table_row_items(**opt)
    # noinspection RubyMismatchedReturnType
    row_items(**opt)
  end

  # The #model_type of individual associated items for iteration.
  #
  # @return [Symbol]
  #
  # @note Not currently used.
  #
  def table_row_model_type
    row_model_type
  end

  # The default CSS class for a table element.
  #
  # @return [String]
  #
  def table_css_class
    'model-table'
  end

  # Indicate whether a table presents as an element with the HTML 'table' role.
  #
  def table_role?
    true
  end

  # The HTML role of the table element.
  #
  # @param [Boolean] table
  #
  # @return [String]
  #
  def table_role(table: table_role?)
    table ? 'table' : 'grid'
  end

  # The HTML role of cells within the table.
  #
  # @param [Boolean] table
  #
  # @return [String]
  #
  def table_cell_role(table: table_role?)
    table ? 'cell' : 'gridcell'
  end

  # The number of rows of associated items per table page.
  #
  # @return [Integer]
  # @return [nil]                     If rows are not paginated.
  #
  def table_page_size
    row_page_size
  end

  # Get a subset of associated items.
  #
  # @param [Hash] opt                 #ROW_PAGE_PARAMS passed to #row_page.
  #
  # @return [Array<Model>]
  #
  def table_row_page(**opt)
    opt[:limit] = table_page_size        unless opt.key?(:limit)
    opt[:rows]  = table_row_items(**opt) unless opt.key?(:rows)
    row_page(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Options used by BaseCollectionDecorator::Table#render_table.
  #
  # @type [Array<Symbol>]
  #
  RENDER_TABLE_OPT = %i[except sort].concat(MODEL_TABLE_OPT).freeze

  # Render the object for use within a table of items.
  #
  # @param [Integer] row
  # @param [Integer] col
  # @param [Hash]    opt              To column except:
  #
  # @option opt [Hash]   :outer_opt   Options to outer (row) element.
  # @option opt [Hash]   :inner_opt   Options to inner (column cell) element.
  # @option opt [Symbol] :outer_tag   If !`opt[:outer_opt][:tag]`; default: :tr
  # @option opt [Symbol] :inner_tag   If !`opt[:inner_opt][:tag]`; Default: :td
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #table_heading
  #
  def render_table_row(row: 1, col: 1, **opt, &blk)
    trace_attrs!(opt)
    t_opt = trace_attrs_from(opt)
    local = opt.extract!(:tag, :outer_tag, :inner_tag, :outer_opt, :inner_opt)
    table = for_html_table?(local[:tag]) # If not rendering HTML table.

    # Get options for outer (row) and inner (column cell) elements.
    o_opt = (local[:outer_opt] || {}).merge('aria-rowindex': row)
    i_opt = (local[:inner_opt] || {}).merge(opt.except!(*RENDER_TABLE_OPT))

    # Get outer and inner element tags.
    o_tag = o_opt.delete(:tag)
    o_tag = local[:outer_tag] || o_tag || (table ? :tr : :div)
    i_tag = i_opt.delete(:tag)
    i_tag = local[:inner_tag] || i_tag || (table ? :td : :div)

    pairs = table_field_values(**opt)
    first = col
    last  = first + pairs.size - 1

    html_tag(o_tag, **o_opt, **t_opt) do
      pairs.map.with_index(first) do |(field, prop), c|
        # noinspection RubyMismatchedArgumentType
        rc_opt = model_rc_options(field, row, c, i_opt)
        append_css!(rc_opt, 'col-first') if c == first
        append_css!(rc_opt, 'col-last')  if c == last
        html_tag(i_tag, 'aria-colindex': c, **rc_opt, **t_opt) do
          blk.(field, prop, index: "#{row}-#{c}", **t_opt)
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # table_entry
  #
  # @param [Hash] opt                 To #render_table_row
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def table_entry(**opt)
    trace_attrs!(opt)
    render_table_row(inner_tag: :td, **opt) do |_field, prop, **f_opt|
      render_pair(nil, prop[:value], **f_opt, prop: prop, no_label: true)
    end
  end

  # Fields and configurations augmented with a :value entry containing the
  # current field value.
  #
  # @param [Boolean] limited          Do not include fields that are :ignored
  #                                     or have the wrong :role.
  # @param [Hash]    opt              Passed to #property_pairs and
  #                                     #table_field_value.
  #
  # @return [Hash{Symbol=>FieldConfig}]
  #
  def table_field_values(limited: true, **opt)
    trace_attrs!(opt)
    t_opt = trace_attrs_from(opt)
    v_opt = opt.extract!(:index, :no_fmt).merge!(t_opt)
    opt[:config] ||= model_table_fields
    property_pairs(**opt).map { |field, prop|
      next if limited && (prop[:ignored] || !user_has_role?(prop[:role]))
      prop[:value] = table_field_value(prop[:value], field: field, **v_opt)
      [field, prop]
    }.compact.to_h
  end

  # Transform a field value for rendering in a table.
  #
  # @param [any, nil]    value        Passed to #list_field_value.
  # @param [Symbol, nil] field        Passed to #list_field_value.
  # @param [Hash]        opt          Passed to #list_field_value.
  #
  # @return [any, nil]
  #
  def table_field_value(value, field:, **opt)
    list_field_value(value, field: field, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Setup row/column HTML options.
  #
  # @param [Symbol, String] field
  # @param [Integer, nil]   row
  # @param [Integer, nil]   col
  # @param [Hash, nil]      opt
  #
  # @return [Hash]
  #
  def model_rc_options(field, row = nil, col = nil, opt = nil)
    fld = html_id(field)
    prepend_css(opt, fld).tap do |html_opt|
      append_css!(html_opt, "row-#{row}") if row
      append_css!(html_opt, "col-#{col}") if col
      html_opt[:'data-field'] ||= field
      html_opt[:role]         ||= table_cell_role
      html_opt[:id]           ||= [fld, row, col].compact.join('-')
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
