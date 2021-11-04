# app/helpers/data_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/data" pages.
#
module DataHelper

  include CssHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All known EMMA record fields (including those not currently in use).
  #
  # @type [Array<Symbol>]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  EMMA_DATA_FIELDS =
    I18n.t('emma.upload.record.emma_data').map { |k, v|
      k if v.is_a?(Hash)
    }.compact.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # table_names
  #
  # @return [Array<String>]
  #
  def table_names
    db_connection(&:tables)
  end

  # Indicate whether *name* is a valid table name.
  #
  # @param [String, Symbol, *] name
  #
  def table_name?(name)
    table_names.include?(name.to_s)
  end

  # table_columns
  #
  # @param [String, Symbol, *] table_name
  #
  # @return [Array<ConnectionAdapters::Column>]
  #
  def table_columns(table_name)
    db_connection { |db| db_columns(db, table_name) }
  end

  # table_column_names
  #
  # @param [String, Symbol, *]    table_name
  # @param [Array<String,Symbol>] cols          Column names; default: "*".
  #
  # @return [Array<String>]
  #
  def table_column_names(table_name, *cols)
    names = table_columns(table_name).map(&:name)
    cols = cols.presence&.map(&:to_s)
    cols ? names.intersection(cols) : names
  end

  # table_column_types
  #
  # @param [String, Symbol, *]    table_name
  # @param [Array<String,Symbol>] cols          Column names; default: "*".
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  def table_column_types(table_name, *cols)
    cols = cols.presence&.map(&:to_sym)
    table_columns(table_name).map { |column|
      name = column.name.to_sym
      [name, column.type] if cols.nil? || cols.include?(name)
    }.compact.to_h
  end

  # table_records
  #
  # @param [String, Symbol, *]    name          Database table name.
  # @param [Array<String,Symbol>] cols          Column names; default: "*".
  # @param [Boolean, nil]         headings      If *false*, don't include the
  #                                               database schema.
  # @param [Boolean, nil]         html          If *true*, produce records as
  #                                               arrays of values.
  # @param [Boolean, nil]         no_raise      If *true*, don't raise
  #                                               exceptions.
  # @param [Boolean, nil]         raise_blank   If *true*, don't ignore blank
  #                                               column names.
  #
  #
  # @return [Array<Hash>]
  # @return [Array<Array>]                      If *html* is *true*.
  #
  def table_records(
    name,
    *cols,
    headings:    true,
    html:        false,
    no_raise:    false,
    raise_blank: false,
    **
  )
    # Validate parameters.
    errors = []
    errors << invalid_table_name(name) unless table_name?(name)
    if cols.present?
      # noinspection RailsParamDefResolve
      cols.map! { |f| f.is_a?(Symbol) ? f.to_s : (f.try(:name) || f) }
      cols, blanks = cols.partition(&:present?)
      if (error = blank_columns(*blanks)).present?
        if raise_blank
          errors << error
        else
          Log.warn { "#{__method__}: #{error} (ignored)" }
        end
      end
      cols, invalid = cols.partition { |f| f.is_a?(String) }
      if invalid.present?
        errors << invalid_columns(*invalid)
      else
        cols.uniq!
      end
    end
    if errors.present?
      error = errors.join('; ').capitalize
      error << '.' unless error.match?(/[[:punct:]]$/)
      Log.warn { "#{__method__}: #{error}" }
      return [] if no_raise
      raise error
    end

    # Generate the first (schema) row if appropriate.
    columns  = table_column_names(name, *cols)
    head_row = headings.presence
    head_row &&= html ? columns : { schema: table_column_types(name, *cols) }

    # Fetch the database table contents.
    data_rows =
      db_connection do |db|
        db_select(db, name, cols, sort: :id) rescue db_select(db, name, cols)
      end
    unless html
      columns.map!(&:to_sym)
      data_rows.map! do |row|
        columns.zip(row).to_h.map { |column, value|
          value = json_parse(value) if column.end_with?('_data')
          [column, value]
        }.to_h
      end
    end

    # Return with heading and data rows.
    [head_row, *data_rows].compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Error message for an invalid table name.
  #
  # @param [String, Symbol] name
  #
  # @return [String]
  #
  def invalid_table_name(name)
    "invalid table name #{name.inspect}"
  end

  # Error message for blank column(s).
  #
  # @param [Array] columns
  #
  # @return [String]
  # @return [nil]                     If no columns are given.
  #
  def blank_columns(*columns)
    return if columns.empty?
    names = 'name'.pluralize(columns.size)
    "blank column #{names}"
  end

  # Error message for invalid column(s).
  #
  # @param [Array] columns
  #
  # @return [String]
  # @return [nil]                     If no columns are given.
  #
  def invalid_columns(*columns)
    return if columns.empty?
    names   = 'name'.pluralize(columns.size)
    columns = columns.map(&:inspect).join(', ')
    "invalid column #{names}: #{columns}"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # db_connection
  #
  # @return [*]                       Return value of block.
  #
  # @yield [db]
  # @yieldparam [ActiveRecord::ConnectionAdapters::AbstractAdapter] db
  #
  def db_connection(&block)
    ActiveRecord::Base.connection_pool.with_connection(&block)
  end

  # db_columns
  #
  # @param [ActiveRecord::ConnectionAdapters::AbstractAdapter] db
  # @param [String, Symbol, *]        table   Database table name.
  #
  # @return [Array<ConnectionAdapters::Column>]
  #
  def db_columns(db, table)
    db.columns(table.to_s)
  end

  # db_select
  #
  # @param [ActiveRecord::ConnectionAdapters::AbstractAdapter] db
  # @param [String, Symbol, *]        table   Database table name.
  # @param [Array<String,Symbol>]     cols    Column names; default: "*".
  # @param [String, Symbol, Array, *] sort
  #
  # @return [Array<Array>]
  #
  def db_select(db, table, cols, sort: nil)
    cols = cols.presence&.join(',') || '*'
    sql = %W(SELECT #{cols} FROM #{table})
    sql << "ORDER BY #{sort}" if sort.present?
    db.query(sql.join(' '))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate HTML to display a database table.
  #
  # @param [Array<Hash>]    records
  # @param [String, Symbol] name        Database table name.
  # @param [Integer]        start_row
  # @param [Hash]           opt         Passed to #html_db_record.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_table(records, name: nil, start_row: 1, **opt)
    css_selector = '.database-table'
    records ||= []
    count     = positive(records.size - 1) || 0
    classes   = [css_selector]
    classes << 'empty' if count.zero?
    html_opt = prepend_classes(classes)
    html_opt[:id] = name if name.present?
    html_div(**html_opt) do
      opt[:first] ||= start_row
      opt[:last]  ||= opt[:first] + [(count - 1), 0].max
      records.map.with_index(start_row) do |record, row|
        html_db_record(record, row: row, **opt)
      end
    end
  end

  # Generate HTML to display a database record.
  #
  # @param [Hash, Array]  fields
  # @param [Integer, nil] row
  # @param [Integer]      start_col
  # @param [Hash]         opt         Passed to #html_db_column except:
  #
  # @option opt [Integer] :first      Index value of the first record.
  # @option opt [Integer] :last       Index value of the last record.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_record(fields, row: nil, start_col: 1, **opt)
    css_selector = '.database-record'
    fields = :empty if fields.blank?
    # noinspection RubyCaseWithoutElseBlockInspection
    type =
      case fields
        when Array  then :array
        when Hash   then :hierarchy
        when Symbol then fields
      end
    first  = opt.delete(:first) || start_col
    last   = opt.delete(:last)
    last ||= first + [(fields.size - 1 if type == :array).to_i, 0].max
    classes = []
    classes << "row-#{row}" if row
    classes << 'row-first'  if row && (row == first)
    classes << 'row-last'   if row && (row == last)
    rec_opt = prepend_classes(opt, css_selector, type, classes)
    html_div(rec_opt) do
      if type == :array
        opt[:first] = first
        opt[:last]  = last
        fields.map.with_index(start_col) do |field, col|
          html_db_column(field, row: row, col: col, **opt)
        end
      elsif type != :empty
        html_db_column(fields, row: row, **opt)
      end
    end
  end

  # Generate HTML to display a database record.
  #
  # @param [*]            field
  # @param [Integer, nil] row
  # @param [Integer, nil] col
  # @param [Integer, nil] first       Index value of the first column.
  # @param [Integer, nil] last        Index value of the last column.
  # @param [Hash]         opt         Passed to #html_db_column.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_column(field, row: nil, col: nil, first: nil, last: nil, **opt)
    css_selector = '.database-column'
    # noinspection RubyCaseWithoutElseBlockInspection
    type =
      case field
        when Array  then :array
        when Hash   then :hierarchy
        when String then :hierarchy if field.start_with?('{')
      end
    classes = []
    classes << "row-#{row}" if row
    classes << "col-#{col}" if col
    classes << 'col-first'  if col && (col == first)
    classes << 'col-last'   if col && (col == last)
    prepend_classes!(opt, css_selector, type, classes)
    html_div(opt) do
      (type == :hierarchy) ? pretty_json(field) : field
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate HTML to display table of EMMA submission field values.
  #
  # @param [Hash]           fields
  # @param [String, Symbol] name      Database table name.
  # @param [Integer]        start_row
  # @param [Hash]           opt       Passed to #html_db_field.
  #
  # @option opt [Integer] :row        Start row (default: 1).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_field_table(fields, name: nil, start_row: 1, **opt)
    css_selector = '.database-counts-table'
    html_opt = { id: name.presence }.compact
    prepend_classes!(html_opt, css_selector)
    html_div(**html_opt) do
      opt[:first] ||= start_row
      opt[:last]  ||= opt[:first] + fields.size - 1
      fields.map.with_index(start_row) do |field_counts, row|
        html_db_field(*field_counts, row: row, **opt)
      end
    end
  end

  # Generate HTML to display a summary of all values for a given EMMA field.
  #
  # @param [Symbol]         field
  # @param [Hash]           values
  # @param [Integer, nil]   row
  # @param [Hash]           opt       Passed to #html_db_column.
  #
  # @option opt [Integer] :first      Index value of the first record.
  # @option opt [Integer] :last       Index value of the last record.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_field(field, values, row: nil, **opt)
    css_selector = '.database-field-counts'
    anchor  = opt.delete(:id)    || field.to_s
    first   = opt.delete(:first) || row
    last    = opt.delete(:last)  || first
    classes = []
    classes << "row-#{row}" if row
    classes << 'row-first'  if row && (row == first)
    classes << 'row-last'   if row && (row == last)
    prepend_classes!(opt, css_selector, classes)
    html_div(opt) do
      field_opt = { class: 'field-name' }
      unless EMMA_DATA_FIELDS.include?(field)
        append_classes!(field_opt, 'invalid')
        field_opt[:title] = 'This is not a valid EMMA data field' # TODO: I18n
      end
      field  = html_div(field, field_opt)
      values = html_db_field_values(values, id: anchor)
      field << values
    end
  end

  # Generate HTML to display a list of values and counts.
  #
  # @param [Array<Array<*,Integer>>] values
  # @param [Hash]                    opt      Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_field_values(values, **opt)
    css_selector = '.field-values'
    prepend_classes!(opt, css_selector)
    html_div(opt) do
      total  = values.values.sum
      values = values.map { |value, count| [count, Array.wrap(value)] }
      values.sort_by! { |count, value| [-count, value.join("\n")] }
      values.prepend([total, 'TOTAL']) # TODO: I18n
      values.map.with_index do |count_item, index|
        count, item = count_item
        classes = %w(value-count value-item)
        classes.map! { |c| "#{c} total" } if index.zero?
        count = html_div(count, class: classes.first)
        item  = html_div(item,  class: classes.last)
        count << item
      end
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
