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
  # :section:
  # ===========================================================================

  public

  # Render model items as a table.
  #
  # @param [Symbol] tag               Potential alternative to :table.
  # @param [String] css               Default: `#table_css_class`.
  # @param [Hash]   opt               Passed to outer #html_tag except
  #                                     #MODEL_TABLE_OPTIONS to render methods.
  #
  # @option opt [ActiveSupport::SafeBuffer] :thead  Pre-generated *thead*.
  # @option opt [ActiveSupport::SafeBuffer] :tbody  Pre-generated *tbody*.
  # @option opt [ActiveSupport::SafeBuffer] :tfoot  Pre-generated *tfoot*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #STICKY_HEAD
  # @see #DARK_HEAD
  #
  def render_table(tag: nil, css: nil, **opt)
    trace_attrs!(opt)
    css ||= table_css_class
    table = for_html_table?(tag)
    tag   = table && :table || tag || :div
    outer = remainder_hash!(opt, *MODEL_TABLE_OPTIONS)
    t_opt = trace_attrs_from(outer)
    opt   = context.slice(*MODEL_TABLE_DATA_OPT).merge!(opt)

    opt[:sticky] = STICKY_HEAD unless opt.key?(:sticky)
    opt[:dark]   = DARK_HEAD   unless opt.key?(:dark)
    opt[:tag]    = tag         unless table

    parts = opt.extract!(*MODEL_TABLE_PART_OPT).compact
    thead = parts[:thead] || table_heading(**opt, **t_opt)
    tbody = parts[:tbody] || table_entries(**opt, **t_opt, separator: nil)
    if thead.is_a?(Array)
      cols, parts[:thead] = thead.size, safe_join(thead)
    else
      cols, parts[:thead] = thead.scan(/<th[>\s]/).size, thead
    end
    if tbody.is_a?(Array)
      rows, parts[:tbody] = tbody.size, safe_join(tbody)
    else
      rows, parts[:tbody] = tbody.scan(/<tr[>\s]/).size, tbody
    end

    limit = positive(opt[:partial])
    full  = (rows < (limit || table_page_size))

    prepend_css!(outer, css, model_type)
    append_css!(outer, "columns-#{cols}")       if cols.positive?
    append_css!(outer, 'sticky-head')           if opt[:sticky]
    append_css!(outer, 'dark-head')             if opt[:dark]
    append_css!(outer, 'pageable')              if opt[:pageable]
    append_css!(outer, 'sortable')              if opt[:sortable]
    append_css!(outer, 'partial')               if opt[:partial]
    append_css!(outer, 'complete')              if full
    outer[:role] = table_role                   if table
    outer[:'data-turbolinks-permanent'] = true  if opt[:sortable]

    html_tag(tag, **outer) do
      table ? parts.map { |k, rows| html_tag(k, rows, **t_opt) } : parts.values
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render one or more entries for use within a *tbody*.
  #
  # @param [Integer]     row          Current row (prior to first entry).
  # @param [String, nil] separator
  # @param [Hash]        opt          Passed to #table_entry except
  #                                     #MODEL_TABLE_DATA_OPT
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If :separator is *nil*.
  #
  def table_entries(row: 1, separator: "\n", **opt)
    trace_attrs!(opt)
    arg   = opt.extract!(*MODEL_TABLE_DATA_OPT)
    p_opt = opt.extract!(:sort).merge!(limit: arg[:partial] || 0)
    rows  = table_row_page(**p_opt)
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
  # @param [Boolean, nil] dark
  # @param [Hash]         opt         Passed to #render_table_row except
  #                                     #MODEL_TABLE_DATA_OPT
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def table_heading(dark: DARK_HEAD, **opt)
    trace_attrs!(opt)
    item  = object.first || object_class.new
    arg   = opt.extract!(*MODEL_TABLE_DATA_OPT)
    inner = opt[:inner_opt] = { tag: :th, role: 'columnheader' }
    append_css!(inner, 'pageable') if arg[:pageable]
    append_css!(inner, 'sortable') if arg[:sortable]
    append_css!(inner, 'partial')  if arg[:partial]
    # noinspection RubyMismatchedArgumentType
    decorate(item).render_table_row(**opt) { |field, prop, **f_opt|
      html_div(class: 'field', **f_opt) do
        prop[:label] || labelize(field)
      end
    }.tap { |line|
      line.prepend(table_spanner(**trace_attrs_from(opt))) if dark
    }
  end

  # Render a hidden row which spans the table.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def table_spanner(css: '.spanner', **opt)
    prepend_css!(opt, css)
    html_tr(role: 'presentation', 'aria-hidden': true, **opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::Table overrides
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
