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
  #                                     #RENDER_TABLE_OPT to render methods.
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
    local = opt.extract!(*RENDER_TABLE_OPT)
    t_opt = trace_attrs_from(opt)
    local = context.slice(*MODEL_TABLE_DATA_OPT).merge!(local)

    local[:sticky] = STICKY_HEAD unless local.key?(:sticky)
    local[:dark]   = DARK_HEAD   unless local.key?(:dark)
    local[:tag]    = tag         unless table

    parts = local.extract!(*MODEL_TABLE_PART_OPT).compact
    thead = parts[:thead] || table_heading(**local, **t_opt)
    tbody = parts[:tbody] || table_entries(**local, **t_opt, separator: nil)
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

    limit = positive(local[:partial])
    max   = limit || table_page_size
    full  = max && (rows < max)

    prepend_css!(opt, css, model_type)
    append_css!(opt, "columns-#{cols}")       if cols.positive?
    append_css!(opt, 'sticky-head')           if local[:sticky]
    append_css!(opt, 'dark-head')             if local[:dark]
    append_css!(opt, 'pageable')              if local[:pageable]
    append_css!(opt, 'sortable')              if local[:sortable]
    append_css!(opt, 'partial')               if local[:partial]
    append_css!(opt, 'complete')              if full
    opt[:role] = table_role                   if table
    opt[:'aria-rowcount'] = rows              if rows.positive?
    opt[:'aria-colcount'] = cols              if cols.positive?
    opt[:'data-turbolinks-permanent'] = true  if local[:sortable]

    # Generate the table, preceded by a link to access the full table if only
    # displaying a partial table here.
    html_tag(tag, **opt, 'data-path': table_path(sort: local[:sort])) {
      table ? parts.map { |k, part| html_tag(k, part, **t_opt) } : parts.values
    }.tap { |result|
      result.prepend(render_full_table_link(rows: rows)) if limit && !full
    }
  end

  ALL_RECORDS = config_term(:table, :all_records).freeze
  ROWS_HERE   = config_term(:table, :rows_here).freeze

  # Render a link to a page for access to the full contents of a table.
  #
  # @param [String, nil]  path        Default: `#table_path`.
  # @param [Integer, nil] rows        Number of records currently rows.
  # @param [String]       css         Characteristic CSS class/selector.
  # @param [Hash]         opt         Passed to enclosing element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_full_table_link(
    path: nil,
    rows: nil,
    css:  '.full-table-link',
    **opt
  )
    link = make_link((path || table_path), ALL_RECORDS)
    rows = interpolate("(#{ROWS_HERE})", rows: rows)
    prepend_css!(opt, css)
    html_tag(:div, link, rows, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The URL path needed to reconstruct the current table.
  #
  # @param [Hash, nil] prm            Default: `#param_values`.
  # @param [Hash]      opt            Optional added URL parameters.
  #
  # @return [String]
  #
  def table_path(prm = nil, **opt)
    prm = (prm || param_values).merge(opt)
    unless ctrlr_type == (base = prm[:controller]&.to_sym)
      case ctrlr_type
        when :org            then dst, src = :id, %i[org  org_id]
        when :user, :account then dst, src = :id, %i[user user_id]
        else                      dst, src = :"#{base}_id", :id
      end
      prm[dst] = prm.extract!(*src).values.first
    end
    if (sort = prm.delete(:sort)).present?
      prm[:sort] = SortOrder.wrap(sort).param_value.presence
    end
    path_for(**prm, controller: ctrlr_type, action: :index)
  end

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
    local = opt.extract!(*MODEL_TABLE_DATA_OPT)
    inner = opt[:inner_opt] = { tag: :th, role: 'columnheader' }
    append_css!(inner, 'pageable') if local[:pageable]
    append_css!(inner, 'sortable') if local[:sortable]
    append_css!(inner, 'partial')  if local[:partial]
    # noinspection RubyMismatchedArgumentType
    decorate(item).render_table_row(**opt) { |field, prop, **f_opt|
      sortable = local[:sortable] && (field != :actions)
      table_column_label(field, prop, **f_opt, sortable: sortable)
    }.tap { |line|
      line.prepend(table_spanner(**trace_attrs_from(opt))) if dark
    }
  end

  # Render a heading element for the given column.
  #
  # @param [Symbol, String]  field
  # @param [FieldConfig]     prop
  # @param [Boolean]         sortable
  # @param [String]          css      Characteristic CSS class/selector.
  # @param [Hash]            opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def table_column_label(field, prop, sortable:, css: '.field', **opt)
    prepend_css!(opt, css)
    label = html_div(**opt) { prop[:label] || labelize(field) }
    label << table_column_sorter if sortable
    label
  end

  # Render a sort toggle element for a colum header.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def table_column_sorter(css: '.sort-toggle', **opt)
    opt[:role] ||= :presentation
    prepend_css!(opt, css)
    html_div(**opt) do
      icons = { ascending: UP_TRIANGLE, descending: DOWN_TRIANGLE }
      icons.map { |dir, icon| symbol_icon(icon, class: "#{dir}-sort-toggle") }
    end
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
