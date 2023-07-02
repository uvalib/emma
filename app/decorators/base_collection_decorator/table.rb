# app/decorators/base_collection_decorator/table.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting tabular display of Model instances.
#
module BaseCollectionDecorator::Table

  include BaseDecorator::Table

  include BaseCollectionDecorator::Common
  include BaseCollectionDecorator::Row

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render model items as a table.
  #
  # @param [Symbol] tag               Potential alternative to :table.
  # @param [String] css               Default: `#table_css_class`.
  # @param [Hash]   opt               Passed to outer #html_tag except:
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
  def render_table(tag: nil, css: nil, **opt)
    css    ||= table_css_class
    table    = for_html_table?(tag)
    tag      = table && :table || tag || :div
    html_opt = remainder_hash!(opt, *MODEL_TABLE_OPTIONS)
    opt.reverse_merge!(sticky: STICKY_HEAD, dark: DARK_HEAD)
    opt[:tag] = tag unless table

    parts = %i[thead tbody tfoot].map { |k| [k, opt.delete(k)] }.to_h.compact
    parts[:thead] ||= table_headings(**opt)
    parts[:tbody] ||= table_entries(**opt)
    cols  = parts[:thead].scan(/<th[>\s]/).size
    if table
      parts = parts.map { |part, content| html_tag(part, content) }
    else
      parts = parts.values
    end

    opt[:role] = table_role if table
    prepend_css!(html_opt, css, model_type)
    append_css!(html_opt, "columns-#{cols}") if cols.positive?
    append_css!(html_opt, 'sticky-head')     if opt[:sticky]
    append_css!(html_opt, 'dark-head')       if opt[:dark]

    scroll_to_top_target << html_tag(tag, *parts, html_opt)
  end

  # Render one or more entries for use within a *tbody*.
  #
  # @param [Integer]     row          Current row (prior to first entry).
  # @param [String, nil] separator
  # @param [Hash]        opt          Passed to #table_entry
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If :separator is *nil*.
  #
  def table_entries(row: 1, separator: "\n", **opt)
    rows  = table_row_page(limit: nil) # TODO: paginate tables
    first = row + 1
    last  = first + rows.size - 1
    rows.map!.with_index(first) do |item, r|
      row_opt = opt.merge(row: r)
      append_css!(row_opt, 'row-first') if r == first
      append_css!(row_opt, 'row-last')  if r == last
      decorate(item).table_entry(**row_opt)
    end
    rows.compact!
    # noinspection RubyMismatchedReturnType
    separator ? safe_join(rows, separator) : rows
  end

  # Render column headings for a table of model items.
  #
  # @param [Integer]                                   row
  # @param [Integer]                                   col
  # @param [Symbol, String, Array<Symbol,String>, nil] columns
  # @param [String, Regexp, Array<String,Regexp>, nil] filter
  # @param [Boolean]                                   dark
  # @param [Hash]                                      opt
  #
  # @option opt [Symbol] :outer_tag   Default: :tr
  # @option opt [Symbol] :inner_tag   Default: :th
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [item, **opt] Allows the caller to generate the item columns.
  # @yieldparam  [Model] item         Single item instance.
  # @yieldparam  [Hash]  opt          Field generation options.
  # @yieldreturn [ActiveSupport::SafeBuffer]
  #
  # @see #DARK_HEAD
  #
  def table_headings(
    row:     1,
    col:     1,
    columns: nil,
    filter:  nil,
    dark:    DARK_HEAD,
    **opt
  )
    tag   = opt.delete(:tag) # Propagated if not rendering an HTML table.
    outer, inner = opt.values_at(:outer_tag, :inner_tag).map { |v| v || tag }
    outer = for_html_table?(outer) && :tr || outer || :div
    inner = for_html_table?(inner) && :th || inner || :div
    opt.except!(*MODEL_TABLE_OPTIONS)

    ob     = object.first
    pairs  = ob && decorate(ob).table_values(columns: columns, filter: filter)
    fields = pairs&.keys || []
    first  = col
    last   = first + fields.size - 1
    fields.map!.with_index(first) do |field, c|
      value   = html_div(labelize(field), class: 'field')
      row_opt = model_rc_options(field, row, c, opt)
      row_opt.merge!(role: 'columnheader', 'aria-colindex': c)
      append_css!(row_opt, 'col-first') if c == first
      append_css!(row_opt, 'col-last')  if c == last
      html_tag(inner, value, row_opt)
    end

    parts = []
    parts << html_tag(outer, class: 'spanner', 'aria-hidden': true) if dark
    parts << html_tag(outer, *fields, 'aria-rowindex': row)
    safe_join(parts)
  end

  # ===========================================================================
  # :section: BaseDecorator::Table overrides
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
  # @see BaseCollectionDecorator::SharedClassMethods#decorator_class
  #
  # @note Not currently used.
  #
  def table_row_model_type
    row_model_type
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
