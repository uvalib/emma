# app/helpers/data_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/data" pages.
#
module DataHelper

  include Emma::Constants
  include Emma::Json

  include CssHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All known EMMA record fields (including those not currently in use).
  #
  # @type [Array<Symbol>]
  #
  EMMA_DATA_FIELDS =
    config_section('emma.upload.record.emma_data')
      .select { |_field, entry| entry.is_a?(Hash) }.keys.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Tables to be displayed after all others.
  #
  # @type [Array<String,Regexp>]
  #
  LATER_TABLES = [
    /^action_/,
    /^active_/,
    'schema_migrations',
    'ar_internal_metadata',
  ].deep_freeze

  # Produce a list of sorted table names.
  #
  # @param [Array<String,Symbol>, nil] names  Default: `DataHelper#table_names`
  #
  # @return [Array<String>]
  #
  def sorted_table_names(names = nil)
    names = (names || table_names).map(&:to_s)
    later =
      LATER_TABLES.flat_map { |match|
        if match.is_a?(Regexp)
          found, names = names.partition { |name| match === name }
          found.sort
        else
          names.delete(match.to_s)
        end
      }.compact
    # noinspection RubyMismatchedReturnType
    names.sort.concat(later)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # table_names
  #
  # @return [Array<String>]
  #
  def table_names
    db_connection(&:tables) || []
  end

  # Indicate whether *name* is a valid table name.
  #
  # @param [any, nil] name            String, Symbol
  #
  def table_name?(name)
    table_names.include?(name.to_s)
  end

  # table_columns
  #
  # @param [any, nil] table_name      String, Symbol
  #
  # @return [Array<ActiveRecord::ConnectionAdapters::Column>]
  #
  def table_columns(table_name)
    db_connection { |db| db_columns(db, table_name) }
  end

  # table_column_names
  #
  # @param [any, nil]             table_name  String, Symbol
  # @param [Array<String,Symbol>] cols        Column names; default: "*".
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
  # @param [any, nil]             table_name  String, Symbol
  # @param [Array<String,Symbol>] cols        Column names; default: "*".
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

  # table_row_count
  #
  # @param [any, nil] table_name      String, Symbol
  #
  # @return [Integer]
  #
  def table_row_count(table_name)
    db_connection { |db| db_row_count(db, table_name) }
  end

  # table_records
  #
  # @param [String,Symbol,any,nil] name       Database table name.
  # @param [Array<String,Symbol>]  cols       Column names; default: "*".
  # @param [Boolean]               headings   If *false*, don't include the
  #                                             database schema.
  # @param [Boolean]               html       If *true*, produce records as
  #                                             arrays of values.
  # @param [Boolean]               fatal      If *false*, don't raise
  #                                             exceptions.
  # @param [Boolean]               no_blanks  If *true*, don't ignore blank
  #                                               column names.
  #
  # @return [Array<Hash>]
  # @return [Array<Array<String>,Hash>]       If *html* is *true*.
  #
  def table_records(
    name,
    *cols,
    headings:  true,
    html:      false,
    fatal:     true,
    no_blanks: false,
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
        if no_blanks
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
      raise error if fatal
      return []
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
        values = columns.zip(row).to_h
        values.each_pair do |column, value|
          values[column] = json_parse(value) if column.end_with?('_data')
        end
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
  # @param [any, nil] name            String, Symbol
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
  # @return [any, nil]                Return value of block.
  #
  # @yield [db]
  # @yieldparam [ActiveRecord::ConnectionAdapters::AbstractAdapter] db
  #
  def db_connection(&blk)
    ActiveRecord::Base.connection_pool.with_connection(&blk)
  end

  # db_columns
  #
  # @param [ActiveRecord::ConnectionAdapters::AbstractAdapter] db
  # @param [String, Symbol, any, nil]   table   Database table name.
  #
  # @return [Array<ActiveRecord::ConnectionAdapters::Column>]
  #
  def db_columns(db, table)
    db.columns(table.to_s)
  end

  # db_select
  #
  # @param [ActiveRecord::ConnectionAdapters::AbstractAdapter] db
  # @param [any, nil]                   table   Table name (String, Symbol).
  # @param [Array<String,Symbol>]       cols    Column names; default: "*".
  # @param [String, Symbol, Array, nil] sort
  #
  # @return [Array<Hash>]
  #
  def db_select(db, table, cols, sort: nil)
    cols = cols.presence&.join(',') || '*'
    sql = %W[SELECT #{cols} FROM #{table}]
    sql << "ORDER BY #{sort}" if sort.present?
    db.query(sql.join(' '))
  end

  # db_row_count
  #
  # @param [ActiveRecord::ConnectionAdapters::AbstractAdapter] db
  # @param [any, nil]                   table   Table name (String, Symbol).
  #
  # @return [Integer]
  #
  def db_row_count(db, table)
    db.query("SELECT count(*) FROM #{table}")&.first&.first || 0
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
  # @param [Array]          cols        Subset of table columns.
  # @param [String]         css         Characteristic CSS class.
  # @param [Hash]           opt         Passed to #html_db_record.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_table(
    records,
    name:       nil,
    start_row:  1,
    cols:       [],
    css:        '.database-table',
    **opt
  )
    records ||= []
    # noinspection RubyMismatchedArgumentType
    tbl_opt = { id: name.presence && html_id(name) }.compact
    headers = name ? table_column_names(name, *cols) : records.first&.keys

    append_css!(tbl_opt, "columns-#{headers.size}") if headers
    append_css!(tbl_opt, 'empty')                   if records.empty?
    prepend_css!(tbl_opt, css)

    html_div(**tbl_opt) do
      opt[:first] ||= start_row
      opt[:last]  ||= opt[:first] + (positive(records.size - 1) || 0)
      opt[:heads] ||= headers.map { |k| html_id(k.try(:name) || k) }
      records.map.with_index(opt[:first]) do |record, row|
        html_db_record(record, row: row, **opt)
      end
    end
  end

  # Generate HTML to display a database record.
  #
  # @param [Hash, Array]  fields
  # @param [Integer, nil] row
  # @param [Integer]      start_col
  # @param [String]       css         Characteristic CSS class.
  # @param [Hash]         opt         Passed to #html_db_column except:
  #
  # @option opt [Integer] :first      Index value of the first record.
  # @option opt [Integer] :last       Index value of the last record.
  # @option opt [Array]   :heads      Column headings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_record(
    fields,
    row:        nil,
    start_col:  1,
    css:        '.database-record',
    **opt
  )
    fields = :empty if fields.blank?
    type =
      case fields
        when Array  then :array
        when Hash   then :hierarchy
        when Symbol then fields
      end
    heads  = opt.delete(:heads) || []
    first  = opt.delete(:first)
    last   = opt.delete(:last)
    # noinspection RubyMismatchedArgumentType
    last ||= first + [(fields.size - 1 if type == :array).to_i, 0].max
    classes = []
    classes << "row-#{row}" if row
    classes << 'row-first'  if row && (row == first)
    classes << 'row-last'   if row && (row == last)
    rec_opt = prepend_css(opt, css, type, classes)
    html_div(**rec_opt) do
      if type == :array
        opt[:first] = start_col
        opt[:last]  = opt[:first] + fields.size - 1
        fields.map.with_index(start_col) do |field, col|
          head = heads[col-start_col]
          html_db_column(field, row: row, col: col, head: head, **opt)
        end
      elsif type != :empty
        html_db_column(fields, row: row, **opt)
      end
    end
  end

  # Generate HTML to display a database record.
  #
  # @param [any, nil]     field
  # @param [Integer, nil] row
  # @param [Integer, nil] col
  # @param [Integer, nil] first       Index value of the first column.
  # @param [Integer, nil] last        Index value of the last column.
  # @param [String, nil]  head        Related column heading.
  # @param [String]       css         Characteristic CSS class.
  # @param [Hash]         opt         Passed to #html_db_column.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_column(
    field,
    row:    nil,
    col:    nil,
    first:  nil,
    last:   nil,
    head:   nil,
    css:    '.database-column',
    **opt
  )
    type =
      case field
        when Hash                        then :hierarchy
        when Array                       then :array
        when BoolType                    then :bool
        when /^{([^",\s]+(,[^,\s]+)*)}$/ then (field = $1.split(',')) && :array
        when /^{/                        then :hierarchy
      end
    classes = []
    classes << "row-#{row}" if row
    classes << "col-#{col}" if col
    classes << head         if head
    classes << 'col-first'  if col && (col == first)
    classes << 'col-last'   if col && (col == last)
    prepend_css!(opt, css, type, classes)
    html_div(**opt) do
      case type
        when :hierarchy then pretty_json(field)
        when :array     then field.join(";\n")
        when :bool      then field
        else                 field || EMPTY_VALUE
      end
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
  # @param [String]         css       Characteristic CSS class.
  # @param [Hash]           opt       Passed to #html_db_field.
  #
  # @option opt [Integer] :row        Start row (default: 1).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_field_table(
    fields,
    name:       nil,
    start_row:  1,
    css:        '.database-counts-table',
    **opt
  )
    html_opt = { id: name.presence }.compact
    prepend_css!(html_opt, css)
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
  # @param [String]         css       Characteristic CSS class.
  # @param [Hash]           opt       Passed to #html_db_column.
  #
  # @option opt [Integer] :first      Index value of the first record.
  # @option opt [Integer] :last       Index value of the last record.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_field(
    field,
    values,
    row:    nil,
    css:    '.database-field-counts',
    **opt
  )
    anchor  = opt.delete(:id)    || field.to_s
    first   = opt.delete(:first) || row
    last    = opt.delete(:last)  || first
    classes = []
    classes << "row-#{row}" if row
    classes << 'row-first'  if row && (row == first)
    classes << 'row-last'   if row && (row == last)
    prepend_css!(opt, css, classes)
    html_div(**opt) do
      field_opt = { class: 'field-name' }
      unless EMMA_DATA_FIELDS.include?(field)
        append_css!(field_opt, 'invalid')
        field_opt[:title] = config_term(:data, :field, :invalid)
      end
      field  = html_div(field, **field_opt)
      values = html_db_field_values(values, id: anchor)
      field << values
    end
  end

  # Generate HTML to display a list of values and counts.
  #
  # @param [Hash]   values
  # @param [String] css               Characteristic CSS class.
  # @param [Hash]   opt               Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_field_values(values, css: '.field-values', **opt)
    prepend_css!(opt, css)
    # noinspection RubyMismatchedArgumentType
    html_div(**opt) do
      total  = values.values.sum
      values = values.map { |value, count| [count, Array.wrap(value)] }
      values.sort_by! { |count, value| [-count, value.join("\n")] }
      values.prepend([total, config_term(:data, :field, :total)])
      values.map.with_index do |count_item, index|
        count, item = count_item
        classes = %w[value-count value-item]
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

  public

  # The subset of columns from #submission_table displayed as submission data.
  #
  # @type [Array<Symbol>]
  #
  SUBMISSION_COLUMNS = %i[
    id
    file_data
    emma_data
    user_id
    repository
    submission_id
    fmt
    ext
    state
    created_at
    updated_at
  ].freeze

  # The table holding EMMA submission entries.
  #
  # @return [String]
  #
  def submission_table
    'uploads'
  end

  # Enumerate the database columns which are relevant to data analysis output.
  #
  # @param [Array<Symbol>, Symbol, nil] columns   Default: #SUBMISSION_COLUMNS
  #
  # @return [Array<Symbol>]
  #
  def submission_result_columns(columns = nil)
    columns &&= Array.wrap(columns).presence&.map(&:to_sym)
    (columns || SUBMISSION_COLUMNS).excluding(:state)
  end

  # Enumerate the record array indicies which are relevant to data analysis.
  #
  # @param [Array<Symbol>, Symbol, nil] columns   Default: #SUBMISSION_COLUMNS
  #
  # @return [Array<Symbol>]
  #
  def submission_result_indices(columns = nil)
    columns = submission_result_columns(columns)
    SUBMISSION_COLUMNS.map.with_index { |col, idx|
      idx if columns.include?(col)
    }.compact
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
