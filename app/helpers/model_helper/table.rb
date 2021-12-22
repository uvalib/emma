# app/helpers/model_helper/table.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting tabular display of Model instances (both
# database items and API messages).
#
module ModelHelper::Table

  include ModelHelper::List

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Make the heading row stick to the top of the table when scrolling.
  #
  # @type [Boolean]
  #
  # @see file:app/assets/stylesheets/shared/controls/_table.scss "CSS class .sticky-head"
  #
  STICKY_HEAD = true

  # Give the heading row a background.
  #
  # @type [Boolean]
  #
  # @see file:app/assets/stylesheets/shared/controls/_table.scss "CSS class .dark-head"
  #
  DARK_HEAD = true

  # Options used by some or all of the methods involved in rendering items in
  # a tabular form.
  #
  # @type [Array<Symbol>]
  #
  MODEL_TABLE_OPTIONS = [
    MODEL_TABLE_FIELD_OPT = %i[columns],
    MODEL_TABLE_HEAD_OPT  = %i[sticky dark],
    MODEL_TABLE_ENTRY_OPT = %i[inner_tag outer_tag],
    MODEL_TABLE_ROW_OPT   = %i[row col],
    MODEL_TABLE_TABLE_OPT = %i[model thead tbody tfoot],
  ].flatten.freeze

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render model items as a table.
  #
  # @param [Model, Array<Model>] list
  # @param [Hash]                opt    Passed to outer #html_tag except for:
  #
  # @option opt [Symbol, String]            :model
  # @option opt [ActiveSupport::SafeBuffer] :thead  Pre-generated <thead>.
  # @option opt [ActiveSupport::SafeBuffer] :tbody  Pre-generated <tbody>.
  # @option opt [ActiveSupport::SafeBuffer] :tfoot  Pre-generated <tfoot>.
  # @option opt [Any] #MODEL_TABLE_OPTIONS          Passed to render methods.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [list, **opt] Allows the caller to define the table contents.
  # @yieldparam  [Hash]         parts   Accumulated :thead/:tbody/:tfoot parts.
  # @yieldparam  [Array<Model>] list    Normalized item list.
  # @yieldparam  [Hash]         opt     Updated options.
  # @yieldreturn [void] Block should update *parts*.
  #
  # @see #STICKY_HEAD
  # @see #DARK_HEAD
  #
  def model_table(list, **opt)
    opt, html_opt = partition_hash(opt, *MODEL_TABLE_OPTIONS)
    opt.reverse_merge!(sticky: STICKY_HEAD, dark: DARK_HEAD)
    list  = Array.wrap(list)
    model = opt.delete(:model) || Model.for(list.first) || 'model'
    css_selector = ".#{model}-table"

    parts = %i[thead tbody tfoot].map { |k| [k, opt.delete(k)] }.to_h
    yield(parts, list, **opt) if block_given?
    parts[:thead] ||= model_table_headings(list, **opt)
    parts[:tbody] ||= model_table_entries(list, **opt)
    count = parts[:thead].scan(/<th[>\s]/).size

    prepend_classes!(html_opt, css_selector)
    append_classes!(html_opt, "columns-#{count}") if count.positive?
    append_classes!(html_opt, 'sticky-head')      if opt[:sticky]
    append_classes!(html_opt, 'dark-head')        if opt[:dark]
    html_tag(:table, html_opt) do
      parts.map { |tag, content| html_tag(tag, content) if content }
    end
  end

  # Render one or more entries for use within a <tbody>.
  #
  # @param [Model, Array<Model>] list
  # @param [String, nil]         separator
  # @param [Integer, nil]        row        Current row (prior to first entry).
  # @param [Hash]                opt        Passed to #model_table_entry
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If :separator is *nil*.
  #
  # @yield [item, **opt] Allows the caller to define the item table entry.
  # @yieldparam  [Model] item         Single item instance.
  # @yieldparam  [Hash]  opt          Row-specific options.
  # @yieldreturn [ActiveSupport::SafeBuffer]
  #
  def model_table_entries(list, separator: "\n", row: 1, **opt)
    rows  = Array.wrap(list).dup
    first = row + 1
    last  = row + rows.size
    rows.map!.with_index(first) do |item, r|
      row_opt = opt.merge(row: r)
      append_classes!(row_opt, 'row-first') if r == first
      append_classes!(row_opt, 'row-last')  if r == last
      if block_given?
        yield(item, **row_opt)
      else
        model_table_entry(item, **row_opt)
      end
    end
    rows.compact!
    separator ? safe_join(rows, separator) : rows
  end

  # Render a single entry for use within a table of items.
  #
  # @param [Model]                                     item
  # @param [Integer]                                   row
  # @param [Integer]                                   col
  # @param [Symbol, String]                            outer_tag
  # @param [Symbol, String]                            inner_tag
  # @param [String, Symbol, Array<String,Symbol>, nil] columns
  # @param [Hash]                                      opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If nil :outer_tag.
  # @return [Array<String>]                     If nil :inner_tag, :outer_tag.
  #
  # @yield [item, **opt] Allows the caller to generate the item columns.
  # @yieldparam  [Model] item         Single item instance.
  # @yieldparam  [Hash]  opt          Field generation options.
  # @yieldreturn [Hash{Symbol=>Any}]  Same as #model_field_values return type.
  #
  def model_table_entry(
    item,
    row:        1,
    col:        1,
    outer_tag:  :tr,
    inner_tag:  :td,
    columns:    nil,
    filter:     nil,
    **opt
  )
    opt.except!(*MODEL_TABLE_OPTIONS)
    fv_opt = { columns: columns, filter: filter }
    pairs  =
      if block_given?
        yield(item, **fv_opt)
      else
        model_field_values(item, **fv_opt)
      end
    fields =
      if inner_tag
        first_col = col
        last_col  = pairs.size + col - 1
        pairs.map do |field, value|
          row_opt = model_rc_options(field, row, col, opt)
          append_classes!(row_opt, 'col-first') if col == first_col
          append_classes!(row_opt, 'col-last')  if col == last_col
          col += 1
          html_tag(inner_tag, value, row_opt)
        end
      else
        pairs.values.compact.map { |value| ERB::Util.h(value) }
      end
    fields = html_tag(outer_tag, fields) if outer_tag
    fields
  end

  # Render column headings for a table of model items.
  #
  # @param [Model, Array<Model>]                       item
  # @param [Integer]                                   row
  # @param [Integer]                                   col
  # @param [Symbol, String]                            outer_tag
  # @param [Symbol, String]                            inner_tag
  # @param [Boolean]                                   dark
  # @param [Symbol, String, Array<Symbol,String>, nil] columns
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
  def model_table_headings(
    item,
    row:        1,
    col:        1,
    outer_tag:  :tr,
    inner_tag:  :th,
    dark:       DARK_HEAD,
    columns:    nil,
    filter:     nil,
    **opt
  )
    opt.except!(*MODEL_TABLE_OPTIONS)

    first  = Array.wrap(item).first
    fv_opt = { columns: columns, filter: filter }
    fields =
      if block_given?
        yield(first, **fv_opt)
      else
        model_field_values(first, **fv_opt)
      end
    fields = fields.dup  if fields.is_a?(Array)
    fields = fields.keys if fields.is_a?(Hash)
    fields = Array.wrap(fields).compact

    if inner_tag
      first_col = col
      last_col  = fields.size + col - 1
      fields.map! do |field|
        row_opt = model_rc_options(field, row, col, opt)
        append_classes!(row_opt, 'col-first') if col == first_col
        append_classes!(row_opt, 'col-last')  if col == last_col
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
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Specified field selections from the given model instance.
  #
  # @param [Model, Hash, nil]                          item
  # @param [String, Symbol, Array<String,Symbol>, nil] columns
  # @param [String, Symbol, Array<String,Symbol>, nil] default
  # @param [String, Regexp, Array<String,Regexp>, nil] filter
  #
  # @return [Hash{Symbol=>Any}]
  #
  def model_field_values(item, columns: nil, default: nil, filter: nil, **)
    # noinspection RailsParamDefResolve
    pairs = item.try(:attributes) || item.try(:stringify_keys)
    return {} if pairs.blank?
    columns = Array.wrap(columns || default).compact_blank.map(&:to_s)
    pairs.slice!(*columns) unless columns.blank? || (columns == %w(all))
    Array.wrap(filter).each do |pattern|
      if pattern.is_a?(Regexp)
        pairs.reject! { |field, _| field.match?(pattern) }
      else
        pairs.reject! { |field, _| field.downcase.include?(pattern) }
      end
    end
    pairs.transform_keys!(&:to_sym)
  end

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
    prepend_classes(opt, field).tap do |html_opt|
      append_classes!(html_opt, "row-#{row}") if row
      append_classes!(html_opt, "col-#{col}") if col
      html_opt[:id] ||= [field, row, col].compact.join('-')
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
