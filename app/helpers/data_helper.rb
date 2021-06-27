# app/helpers/data_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/data" pages.
#
module DataHelper

  # @private
  def self.included(base)
    __included(base, 'DataHelper')
  end

  include CssHelper

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
    result  = []
    columns = table_column_names(name, *cols)
    if headings
      if html
        result << columns
      else
        result << { schema: table_column_types(name, *cols) }
      end
    end

    # Fetch the database table contents.
    result +=
      db_connection { |db|
        db_select(db, name, cols, sort: :id) rescue db_select(db, name, cols)
      }.tap do |rows|
        unless html
          columns.map!(&:to_sym)
          rows.map! do |row|
            columns.zip(row).to_h.map { |column, value|
              value = json_parse(value) if column.end_with?('_data')
              [column, value]
            }.to_h
          end
        end
      end
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
  # @yield [db]
  # @yieldparam [ActiveRecord::ConnectionAdapters::AbstractAdapter] db
  #
  # @return [*]                       Return value of block.
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
  # @param [Array]          records
  # @param [String, Symbol] name      Database table name.
  # @param [Hash]           opt       Passed to #html_db_record.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_table(records, name: nil, **opt)
    css_selector = '.database-table'
    records ||= []
    empty     = (:empty if records.blank?)
    html_opt  = { id: name.presence }.compact
    prepend_classes!(html_opt, css_selector, empty)
    html_div(**html_opt) do
      opt[:first] ||= 1
      opt[:last]  ||= opt[:first] + records.size
      if empty
        html_db_record([], row: 1, **opt)
      else
        records.map.with_index(1) do |record, row|
          html_db_record(record, row: row, **opt)
        end
      end
    end
  end

  # Generate HTML to display a database record.
  #
  # @param [Array]          fields
  # @param [Integer, nil]   row
  # @param [Hash]           opt       Passed to #html_db_column.
  #
  # @option opt [Integer] :first      Index value of the first record.
  # @option opt [Integer] :last       Index value of the last record.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_db_record(fields, row: nil, **opt)
    css_selector = '.database-record'
    type =
      case fields
        when Array  then :array
        when Hash   then :hierarchy
        else             fields = :empty if fields.blank?
      end
    classes = []
    if row
      opt[:first] ||= 1
      opt[:last]  ||= opt[:first] + fields.size
      classes << "row-#{row}"
      classes << 'row-first' if row == opt[:first]
      classes << 'row-last'  if row == opt[:last]
    end
    rec_opt = prepend_classes(opt, css_selector, type, classes)
    html_div(rec_opt) do
      if type == :array
        opt[:first] = 1
        opt[:last]  = opt[:first] + fields.size
        fields.map.with_index(1) do |field, col|
          html_db_column(field, row: row, col: col, **opt)
        end
      else
        html_db_column(fields, row: row, **opt.except(:first, :last))
      end
    end
  end

  # Generate HTML to display a database record.
  #
  # @param [*]              field
  # @param [Integer, nil]   row
  # @param [Integer, nil]   col
  # @param [Integer, nil]   first     Index value of the first column.
  # @param [Integer, nil]   last      Index value of the last column.
  # @param [Hash]           opt       Passed to #html_db_column.
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
    field = pretty_json(field) if type == :hierarchy
    classes = []
    classes << "row-#{row}" if row
    classes << "col-#{col}" if col
    classes << 'col-first'  if col && (col == first)
    classes << 'col-last'   if col && (col == last)
    prepend_classes!(opt, css_selector, type, classes)
    html_div(field, opt)
  end

end

__loading_end(__FILE__)
