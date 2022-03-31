# app/decorators/base_collection_decorator/table.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting tabular display of Model instances.
#
module BaseCollectionDecorator::Table

  include BaseDecorator::Table

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render model items as a table.
  #
  # @param [Hash] opt                 Passed to outer #html_tag except:
  #
  # @option opt [ActiveSupport::SafeBuffer] :thead  Pre-generated *thead*.
  # @option opt [ActiveSupport::SafeBuffer] :tbody  Pre-generated *tbody*.
  # @option opt [ActiveSupport::SafeBuffer] :tfoot  Pre-generated *tfoot*.
  # @option opt [Any] #MODEL_TABLE_OPTIONS          Passed to render methods.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #STICKY_HEAD
  # @see #DARK_HEAD
  #
  def table(**opt)
    css      = '.model-table'
    html_opt = remainder_hash!(opt, *MODEL_TABLE_OPTIONS)
    opt.reverse_merge!(sticky: STICKY_HEAD, dark: DARK_HEAD)

    parts = %i[thead tbody tfoot].map { |k| [k, opt.delete(k)] }.to_h
    parts[:thead] ||= table_headings(**opt)
    parts[:tbody] ||= table_entries(**opt)
    count = parts[:thead].scan(/<th[>\s]/).size

    prepend_css!(html_opt, css, model_type)
    append_css!(html_opt, "columns-#{count}") if count.positive?
    append_css!(html_opt, 'sticky-head')      if opt[:sticky]
    append_css!(html_opt, 'dark-head')        if opt[:dark]
    html_tag(:table, html_opt) do
      parts.map { |tag, content| html_tag(tag, content) if content }
    end
  end

  # Render one or more entries for use within a *tbody*.
  #
  # @param [Integer, nil] row         Current row (prior to first entry).
  # @param [String, nil]  separator
  # @param [Hash]         opt         Passed to #table_entry
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If :separator is *nil*.
  #
  def table_entries(row: 1, separator: "\n", **opt)
    rows  = object.dup
    first = row + 1
    last  = row + rows.size
    rows.map!.with_index(first) do |item, r|
      row_opt = opt.merge(row: r)
      append_css!(row_opt, 'row-first') if r == first
      append_css!(row_opt, 'row-last')  if r == last
      decorate(item).table_entry(**row_opt)
    end
    rows.compact!
    separator ? safe_join(rows, separator) : rows
  end

  # Render column headings for a table of model items.
  #
  # @param [Integer]                                   row
  # @param [Integer]                                   col
  # @param [Symbol, Integer, nil]                      outer_tag
  # @param [Symbol, Integer, nil]                      inner_tag
  # @param [Symbol, String, Array<Symbol,String>, nil] columns
  # @param [String, Regexp, Array<String,Regexp>, nil] filter
  # @param [Boolean]                                   dark
  # @param [Hash]                                      opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If nil :outer_tag.
  # @return [Array<String>]                     If nil :inner_tag, :outer_tag.
  #
  # @yield [item, **opt] Allows the caller to generate the item columns.
  # @yieldparam  [Model] item         Single item instance.
  # @yieldparam  [Hash]  opt          Field generation options.
  # @yieldreturn [ActiveSupport::SafeBuffer]
  #
  # @see #DARK_HEAD
  #
  def table_headings(
    row:        1,
    col:        1,
    outer_tag:  :tr,
    inner_tag:  :th,
    columns:    nil,
    filter:     nil,
    dark:       DARK_HEAD,
    **opt
  )
    opt.except!(*MODEL_TABLE_OPTIONS)

    first  = object.first
    fv_opt = { columns: columns, filter: filter }
    fields = first && decorate(first).table_columns(**fv_opt)
    fields = fields.dup  if fields.is_a?(Array)
    fields = fields.keys if fields.is_a?(Hash)
    fields = Array.wrap(fields).compact

    if inner_tag
      first_col = col
      last_col  = fields.size + col - 1
      fields.map! do |field|
        row_opt = model_rc_options(field, row, col, opt)
        append_css!(row_opt, 'col-first') if col == first_col
        append_css!(row_opt, 'col-last')  if col == last_col
        col += 1
        html_tag(inner_tag, row_opt) do
          html_div(labelize(field), class: 'field')
        end
      end
    else
      fields.map! { |field| labelize(field) }
    end

    if outer_tag
      fields = html_tag(outer_tag, fields)
      fields = html_tag(outer_tag, '', class: 'spanner') << fields if dark
    end

    fields
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
