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
    trace_attrs!(opt)
    css ||= table_css_class
    table = for_html_table?(tag)
    tag   = table && :table || tag || :div
    outer = remainder_hash!(opt, *MODEL_TABLE_OPTIONS)
    t_opt = trace_attrs_from(outer)

    opt[:sticky] = STICKY_HEAD unless opt.key?(:sticky)
    opt[:dark]   = DARK_HEAD   unless opt.key?(:dark)
    opt[:tag]    = tag         unless table

    parts = opt.extract!(*MODEL_TABLE_PART_OPT).compact
    parts[:thead] ||= table_heading(**opt, **t_opt)
    parts[:tbody] ||= table_entries(**opt, **t_opt)
    cols  = parts[:thead].scan(/<th[>\s]/).size

    prepend_css!(outer, css, model_type)
    append_css!(outer, "columns-#{cols}") if cols.positive?
    append_css!(outer, 'sticky-head')     if opt[:sticky]
    append_css!(outer, 'dark-head')       if opt[:dark]
    outer[:role] = table_role             if table

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
  # @param [Hash]        opt          Passed to #table_entry
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If :separator is *nil*.
  #
  def table_entries(row: 1, separator: "\n", **opt)
    trace_attrs!(opt)
    rows  = table_row_page(limit: 0) # TODO: paginate tables
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
  # @param [Hash]         opt         To #render_table_row
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def table_heading(dark: DARK_HEAD, **opt)
    trace_attrs!(opt)
    opt[:inner_opt] = { tag: :th, role: 'columnheader' }
    item = object.first || object_class.new
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
