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
  # @see file:stylesheets/layouts/controls/_tables.scss "CSS class .sticky-head"
  #
  STICKY_HEAD = true

  # Give the heading row a background.
  #
  # @type [Boolean]
  #
  # @see file:stylesheets/layouts/controls/_tables.scss "CSS class .dark-head"
  #
  DARK_HEAD = true

  # Options used by some or all of the methods involved in rendering items in
  # a tabular form.
  #
  # @type [Array<Symbol>]
  #
  MODEL_TABLE_OPTIONS = [
    :model,
    *FIELD_VALUES_OPT,
    MODEL_TABLE_HEAD_OPT  = %i[sticky dark],
    MODEL_TABLE_ENTRY_OPT = %i[outer_tag inner_tag],
    MODEL_TABLE_ROW_OPT   = %i[row col],
    MODEL_TABLE_PART_OPT  = %i[thead tbody tfoot],
  ].flatten.freeze

  # Default number of rows per table page.
  #
  # @type [Integer]
  #
  TABLE_PAGE_SIZE = ROW_PAGE_SIZE

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The collection of items to be presented in tabular form.
  #
  # @return [Array<Model>]
  # @return [ActiveRecord::Relation]
  # @return [ActiveRecord::Associations::CollectionAssociation]
  #
  def table_row_items
    # noinspection RubyMismatchedReturnType
    row_items
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
  #
  def table_page_size
    TABLE_PAGE_SIZE
  end

  # Get a subset of associated items.
  #
  # @param [Hash] opt                 #ROW_PAGE_PARAMS passed to #row_page.
  #
  # @return [Array<Model>]
  #
  def table_row_page(**opt)
    opt[:rows]  = table_row_items unless opt.key?(:rows)
    opt[:limit] = table_page_size unless opt.key?(:limit)
    row_page(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render the object for use within a table of items.
  #
  # @param [Integer] row
  # @param [Integer] col
  # @param [Hash]    opt              To column except:
  #
  # @option opt [Symbol]                :outer_tag  Default: :tr
  # @option opt [Symbol]                :inner_tag  Default: :td
  # @option opt [Symbol, String, Array] :columns    To #table_values
  # @option opt [String, Regexp, Array] :filter     To #table_values
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #table_headings
  #
  def table_entry(row: 1, col: 1, **opt)
    tag    = opt.delete(:tag) # Propagated if not rendering an HTML table.
    outer, inner = opt.values_at(*MODEL_TABLE_ENTRY_OPT).map { |v| v || tag }
    outer  = for_html_table?(outer) && :tr || outer || :div
    inner  = for_html_table?(inner) && :td || inner || :div
    fv_opt = opt.slice(*FIELD_VALUES_OPT)
    opt.except!(*MODEL_TABLE_OPTIONS)

    pairs  = table_values(**fv_opt)
    first  = col
    last   = first + pairs.size - 1
    fields =
      pairs.map.with_index(first) do |(field, value), c|
        # noinspection RubyMismatchedArgumentType
        row_opt = model_rc_options(field, row, c, opt)
        row_opt.merge!('aria-colindex': c)
        append_css!(row_opt, 'col-first') if c == first
        append_css!(row_opt, 'col-last')  if c == last
        html_tag(inner, value, row_opt)
      end

    html_tag(outer, *fields, 'aria-rowindex': row)
  end

  # Table values associated with the current decorator.
  #
  # @param [Hash] opt                 Passed to #model_field_values
  #
  # @return [Hash]
  #
  def table_values(**opt)
    model_field_values(**opt)
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
    field = html_id(field)
    prepend_css(opt, field).tap do |html_opt|
      append_css!(html_opt, "row-#{row}") if row
      append_css!(html_opt, "col-#{col}") if col
      html_opt[:role] ||= table_cell_role
      html_opt[:id]   ||= [field, row, col].compact.join('-')
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
