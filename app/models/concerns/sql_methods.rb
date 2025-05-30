# app/models/concerns/sql_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common SQL methods for database record models.
#
# TODO: Postgres 11 handling of JSON?
#
# @see https://www.postgresql.org/about/featurematrix/
# @see https://www.postgresql.org/docs/11/datatype-json.html
# @see https://www.postgresql.org/docs/11/functions-json.html
# @see https://www.postgresql.org/docs/11/hstore.html
# @see https://www.postgresql.org/docs/11/functions-aggregate.html
# @see https://www.postgresql.org/docs/11/functions-textsearch.html
#
module SqlMethods

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  SQL_NUM         = '-?(\d+(\.\d*)?|\.\d+)'
  SQL_NUM_OP      = %w[!= = <> <= < >= >].join('|').freeze

  SQL_NUMBER      = /^#{SQL_NUM}$/.freeze
  SQL_COMPARISON  = /^(#{SQL_NUM_OP})\s*(#{SQL_NUM})$/.freeze
  SQL_PATTERN     = /^[%_]|[^\\][%_]/.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether two records match.
  #
  # @param [ApplicationRecord] rec_1
  # @param [ApplicationRecord] rec_2
  #
  def match?(rec_1, rec_2)
    (rec_1.is_a?(ApplicationRecord) || rec_2.is_a?(ApplicationRecord)) &&
      (rec_1.class.try(:base_class) == rec_2.class.try(:base_class)) &&
      (rec_1.attributes == rec_2.attributes)
  end

  # Translate hash keys/values into SQL conditions combined by AND.
  #
  # @param [Array<Hash,Array,String>] terms
  # @param [Hash]                     other   Additional terms.
  #
  # @return [String]
  #
  def sql_and(*terms, **other)
    if other.key?(:join)
      Log.warn { "#{__method__}: join #{other[:join].inspect} ignored" }
    end
    sql_terms(*terms, **other, join: :and)
  end

  # Translate hash keys/values into SQL conditions combined by OR.
  #
  # @param [Array<Hash,Array,String>] terms
  # @param [Hash]                     other   Additional terms.
  #
  # @return [String]
  #
  def sql_or(*terms, **other)
    if other.key?(:join)
      Log.warn { "#{__method__}: join #{other[:join].inspect} ignored" }
    end
    sql_terms(*terms, **other, join: :or)
  end

  # Translate hash keys/values into SQL conditions.
  #
  # If *join* is set to *nil*, an array of SQL clauses is returned instead.
  #
  # @param [Array<Hash,Array,String>] terms
  # @param [Symbol, nil]              join    Either :or or :and; default: :and
  # @param [Hash]                     other   Additional terms.
  #
  # @return [String]
  #
  # === Examples
  #
  # @example Single term - Hash
  #   cond = { age: '18', hgt = 1.8 }
  #   sql_terms(cond) -> "age = '18' AND hgt = '1.8'"
  #
  # @example Single term - SQL
  #   ids = 'id IN (123, 456)'
  #   sql_terms(ids) -> "(id IN (123, 456))"
  #
  # @example Multiple terms
  #   sql_clauses(cond, ids)-> "age='18' AND hgt='1.8' AND (id IN (123, 456))"
  #
  def sql_terms(*terms, join: :and, **other)
    terms = terms.flatten.compact_blank
    terms << other if other.present?
    terms.map! { _1.is_a?(Hash) ? sql_clauses(_1, join: join) : _1 }
    sql_join(*terms, join)
  end

  # Translate hash keys/values into SQL conditions.
  #
  # @param [Hash]        hash
  # @param [Symbol, nil] join         Either :or or :and; default: :and
  #
  # @return [String]                  SQL expression.
  # @return [Array]                   SQL clauses if *join* is set to *nil*.
  #
  # === Examples
  #
  # @example AND-ed values
  #   sql_clauses(id: '123', age: '18') -> "id = '123' AND age = '18'"
  #
  # @example OR-ed values
  #   sql_clauses(id: '123', age: '18', join: :or)-> "id = '123' OR age = '18'"
  #
  def sql_clauses(hash, join: :and)
    clauses = hash.map { sql_clause(_1, _2) }
    sql_join(*clauses, join)
  end

  # Translate a key and value into a SQL condition.
  #
  # @param [String, Symbol, Hash] k
  # @param [any, nil]             v
  #
  # @return [String, nil]
  #
  #--
  # === Variations
  #++
  #
  # @overload sql_clause(k, v)
  #   @param [String, Symbol] k
  #   @param [any, nil]       v
  #
  # @overload sql_clause(hash)
  #   @param [Hash] hash              Only the first pair is used.
  #
  # === Examples
  #
  # @example Single value
  #   sql_clause(:id, '123') -> "id = '123'"
  #
  # @example Single value as a hash
  #   sql_clause(id: '123')  -> "id = '123'"
  #
  # @example Multiple values
  #   sql_clause(:id, %w[123 456 789]) -> "id IN ('123','456','789')"
  #
  # @example Multiple values as a hash
  #   sql_clause(id: %w[123 456 789])  -> "id IN ('123','456','789')"
  #
  def sql_clause(k, v = nil)
    k, v = *k.first   if k.is_a?(Hash)
    v = Array.wrap(v) if v.is_a?(Range)
    if v.is_a?(String)
      v = v.strip
      if v != (unquoted = strip_quotes(v))
        v = unquoted
      elsif v.include?(',')
        v = v.split(/\s*,\s*/)
      end
    end
    return sql_test(k, v)  unless v.is_a?(Array)
    v = v.uniq
    if v.many? && (v.map(&:class).uniq.size == 1)
      ranges = v.sort.chunk_while { |prev, this| prev.succ == this }.to_a
      ranges.map! { (_1.size >= 5) ? Range.new(_1.first, _1.last) : _1 }
      ranges, singles = ranges.partition { _1.is_a?(Range) }
      ranges.map! { sql_test(k, _1) }
      singles.flatten!
    else
      ranges  = []
      singles = v
    end
    if singles.present?
      singles.map! { sql_quote(_1) }
      ranges << "#{k} IS NULL"                     if singles.reject!(&:nil?)
      ranges << "#{k} IN (%s)" % singles.join(',') if singles.present?
    end
    if ranges.many?
      ranges.map! { "(#{_1})" }.join(' OR ')
    else
      ranges.first
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Join SQL terms, with multiple terms fully parenthesized.
  #
  # @param [Array<String,Array>] terms
  # @param [Symbol, nil]         join   Either :or or :and.
  #
  # @return [String]
  # @return [Array<String>]             If *join* is *nil*.
  #
  def sql_join(*terms, join)
    terms = terms.flatten.compact_blank
    return terms             if join.nil?
    return terms.first || '' unless terms.many?
    terms.map! { _1.start_with?('(') ? _1 : "(#{_1})" }
    '(%s)' % terms.join(" #{join} ".upcase)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Look for a value in a standard database field.
  #
  # @param [Symbol, String] column
  # @param [any, nil]       value
  # @param [Hash]           opt       Passed to #sql_test
  #
  # @return [String]
  #
  def sql_match_pattern(column, value, **opt)
    '(%s)' % sql_test(column, value, **opt)
  end

  # Look for value in a JSON-type database column.
  #
  # @note This was written for MySQL and has not been translated for Postgres.
  #
  # @param [Symbol, String] column
  # @param [String, #to_s]  term
  # @param [Hash]           opt       Passed to #sql_match_term
  #
  # @return [String]
  #
  # @see https://dev.mysql.com/doc/refman/8.0/en/json-function-reference.html
  # @see https://stackoverflow.com/questions/49782240/can-i-do-case-insensitive-search-with-json-extract-in-mysql
  #
  # === Usage Notes
  # Does not handle "exact: false" for field names yet, only field values.
  #
  def sql_match_json(column, term, **opt)

    # JSON_CONTAINS(json_doc, candidate[, path])
    # JSON_CONTAINS_PATH(json_doc, 'one'|'all', path[, path, ...])
    # JSON_EXTRACT(json_doc, path[, path, ...])
    # JSON_KEYS(json_doc[, path])
    # JSON_OVERLAPS(json_doc1, json_doc2)
    # JSON_SEARCH(json_doc, 'one'|'all', search_str[, esc_char[, path, ...]])
    # JSON_VALUE(json_doc, path)

    key, value =
      if term.is_a?(String) && term.include?(':')
        term.split(':', 2)
      else
        [nil, term]
      end

    if key.blank?
      name, _match, value = sql_name_value(column, value, **opt)
      "(JSON_SEARCH(#{name}, 'one', #{value}) IS NOT NULL)"

    elsif (value = value&.to_s&.strip).blank? || (value == '*')
      Log.warn("#{__method__}: fld match always exact") if false?(opt[:exact])
      "JSON_CONTAINS_PATH(#{column}, '$.#{key}')"

    else
      # func = match_case ? "#{column}->'$.#{key}'" : "CAST(#{column}->>'$.#{key}' AS TEXT)"
      func = "JSON_EXTRACT(#{column}, '$.#{key}')"
      func = "CAST(JSON_UNQUOTE(#{func}) AS TEXT)" unless opt[:match_case]
      sql_match_pattern(func, value, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a SQL JSON_TABLE definition.
  #
  # @param [Symbol, String]              column
  # @param [String, nil]                 name       Def: derived from *column*.
  # @param [Symbol, String, Array]       fields     JSON fields for *column*.
  # @param [Hash{Symbol=>Array<Symbol>}] field_map  If *fields* not given.
  #
  # @return [String]
  #
  # === Implementation Notes
  # * Documentation indicates that '$[*]' should work but only '$' seems to.
  #
  def sql_json_table(column, name: nil, fields: nil, field_map: nil)
    alias_name   = name   || "#{column}_columns"
    json_fields  = fields || field_map&.dig(column)
    json_columns =
      Array.wrap(json_fields).map { |key|
        column_name = key.presence && sanitize_sql_name(column, key)
        "#{column_name} JSON PATH '$.#{key}' NULL ON EMPTY" if column_name
      }.join(', ')
    "JSON_TABLE(#{column}, '$' COLUMNS(#{json_columns})) AS #{alias_name}"
  end

  # Generate condition(s) for a WHERE clause.
  #
  # @param [Hash{Symbol=>Array<Symbol>}] field_map  For JSON fields.
  # @param [Hash{Symbol=>Hash}]          param_map  For JSON fields.
  # @param [Hash]                        matches    Field assertions.
  #
  # @return [String]                  Blank if no valid field assertions.
  #
  def sql_where_clause(field_map: nil, param_map: nil, **matches)
    error       = []
    fm_valid    = field_map.is_a?(Hash)
    pm_valid    = param_map.is_a?(Hash)
    json_fields = fm_valid && pm_valid
    unless json_fields || (!field_map && !param_map)
      error << 'have field_map but missing param_map' if fm_valid && !param_map
      error << 'have param_map but missing field_map' if pm_valid && !field_map
      field_map = nil if fm_valid
      param_map = nil if pm_valid
      error << "field_map: #{field_map.class} instead of Hash" if field_map
      error << "param_map: #{param_map.class} instead of Hash" if param_map
    end
    matches.map { |field, value|
      name =
        if json_fields
          column, _ = field_map.find { |_, fields| fields.include?(field) }
          json_field =
            if column
              field
            else
              col_part, fld_part = field.to_s.split('_', 2).map(&:to_sym)
              column, _  = field_map.find { |_, flds| flds.include?(fld_part) }
              fld_part if column == col_part
            end
          sanitize_sql_name(*param_map.dig(column, json_field)) if json_field
        end
      name ||= (field if field_names.include?(field))
      if name.blank?
        error << "ignoring invalid field #{field.inspect}" and next
      end
      sql_test(name, value)
    }.compact.map! { "(#{_1})" }.join(' AND ').tap {
      error.each { Log.warn("#{self.class}.#{__method__}: #{_1}") }
    }
  end

  # Generate the SQL fragment which is the test of a name against a value.
  #
  # @param [any, nil] name
  # @param [any, nil] value
  # @param [Hash]     opt             Passed to #sql_name_value
  #
  # @return [String]
  #
  def sql_test(name, value, **opt)
    sql_name_value(name, value, **opt).join(' ')
  end

  # Generate the SQL fragment elements for testing a name against a value.
  #
  # @param [any, nil] name
  # @param [any, nil] value
  # @param [Hash]     opt             Passed to #sql_match_term
  #
  # @return [Array(String,String,String)]
  #
  def sql_name_value(name, value, **opt)
    opt.merge!(exact: true, match_case: true) if uuid?(value)
    match, term = sql_match_term(value, **opt)
    if !opt[:match_case] && !name.match?(/lower\(/i) && term.match?(/'\)?$/)
      name = "CAST(lower(#{name}) AS TEXT)"
    end
    [name, match, term]
  end

  # Generate the SQL operator and value from a term.
  #
  # @param [any, nil] term
  # @param [Boolean]  exact
  # @param [Boolean]  match_case
  #
  # @return [Array(String,String)]
  #
  # @see #sql_test
  #
  def sql_match_term(term, exact: false, match_case: false, **)
    case term
      when nil
        term = term.to_s
      when String
        term = term.strip
      when Symbol
        term = term.to_s.downcase if %i[nil null NULL * any ANY].include?(term)
      when Range
        return 'BETWEEN', ('%s AND %s' % term.minmax.map { sql_quote(_1) })
      when Array
        return 'IN', sql_list(term)
      else
        return '=', term.to_s
    end
    uuid  = uuid?(term)
    exact = match_case = true if uuid
    term  = term.downcase     unless match_case
    return 'IS', 'NULL'       if %w[nil null NULL].include?(term)
    return 'IS', 'NOT NULL'   if %w[* any ANY].include?(term)
    return '=',  "'#{term}'"  if term.is_a?(Symbol)
    return '=',  term         if term.match(SQL_NUMBER)
    return $1,   $2           if term.match(SQL_COMPARISON)
    pattern = ->(v) { !uuid && v.match?(SQL_PATTERN) }
    term    = "%#{term}%" unless exact || pattern.(term)
    match   = (exact && !pattern.(term)) ? '=' : 'LIKE'
    return match, "'#{term}'"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Mapping of digits to visibly similar letters.
  #
  # @type [Hash{String=>String}]
  #
  DIGIT_TO_ALPHA = { '0' => 'O', '1' => 'l', '5' => 'S' }.deep_freeze

  # Some JSON key names have numbers in them but SQL seems to have a problem
  # with that for the names defined within "COLUMNS()".
  #
  # @param [Array<String,Symbol>] name
  #
  # @return [String]
  # @return [nil]                     If *name* was blank.
  #
  def sanitize_sql_name(*name)
    name.join('_').presence&.gsub(/\d/) { DIGIT_TO_ALPHA[_1] || '_' }
  end

  # Make a string safe to use within an SQL LIKE statement.
  #
  # @param [String] text
  # @param [String] escape_character
  #
  # @return [String]
  #
  # @see ActiveRecord::Sanitization::ClassMethods#sanitize_sql_like
  #
  def sanitize_sql_like(text, escape_character = '\\')
    text.to_s.gsub(/(^|.)([%_])/) do |s|
      ($1 == escape_character) ? s : [$1, escape_character, $2].compact.join
    end
  end

  # Return the value, quoted if necessary.
  #
  # @param [String, Symbol, Float, Integer, nil] value
  # @param [String, nil]                         null
  #
  # @return [String, Float, Integer, nil]
  #
  def sql_quote(value, null: nil)
    return 'TRUE'      if true?(value)
    return 'FALSE'     if false?(value)
    value = value.to_s if value.is_a?(Symbol)
    case value
      when nil, 'nil', 'null', 'NULL' then null
      when /^-?\d+$/                  then value.to_i
      when SQL_NUMBER                 then value.to_f
      when String                     then "'#{value}'"
      else                                 value
    end
  end

  # Return a list of SQL values.
  #
  # @param [any, nil]    value
  # @param [String, nil] null
  #
  # @return [String]
  #
  def sql_list(value, null: 'NULL')
    '(%s)' % Array.wrap(value).map { sql_quote(_1, null: null) }.join(', ')
  end

  # ===========================================================================
  # :section: Instance methods
  # ===========================================================================

  public

  module InstanceMethods

    include SqlMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The fields defined in the schema for this record.
    #
    # @return [Array<Symbol>]
    #
    def field_names
      @field_names ||= attribute_names.map(&:to_sym)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Translate hash keys/values into SQL LIKE statements.
    #
    # If *join* is set to *nil*, an array of SQL clauses is returned instead.
    #
    # @param [Array<Hash,String>] terms
    # @param [Symbol, nil]        join    Either :or or :and; default: :and
    # @param [Hash]               opt     Passed to #merge_match_terms.
    #
    # @return [String]
    #
    def sql_match(*terms, join: :and, **opt)
      json = (opt[:type] == :json)
      merge_match_terms(*terms, **opt).flat_map { |field, matches|
        matches.map do |value|
          json ? sql_match_json(field, value) : sql_match_pattern(field, value)
        end
      }.then { join ? _1.join(" #{join} ".upcase) : _1 }
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Accumulate match pairs.
    #
    # @param [String, Array, Hash] terms
    # @param [Hash]                opt    Passed to #merge_match_terms!
    #
    def merge_match_terms(*terms, **opt)
      merge_match_terms!({}, *terms, **opt)
    end

    # Accumulate match pairs.
    #
    # @param [Hash]                dst
    # @param [String, Array, Hash] terms
    # @param [Array<Symbol>]       columns    Limit fields to match.
    # @param [Symbol]              type       Ignored unless :json.
    # @param [Boolean]             sanitize   If *false*, don't escape '%', '_'
    #
    # @return [Hash{Symbol=>Array<String>}] The modified *dst* hash.
    #
    def merge_match_terms!(
      dst,
      *terms,
      columns:  nil,
      type:     nil,
      sanitize: (type != :json),
      **        # Ignore any others
    )
      columns &&= Array.wrap(columns).map(&:to_sym).intersection(field_names)
      columns ||= field_names
      terms.flatten.each do |term|
        case term
          when nil  then next
          when Hash then term = term.deep_symbolize_keys
          else           term = columns.map { [_1, term] }.to_h
        end
        term.transform_values! { |v|
          next if (v = Array.wrap(v).compact_blank).empty?
          sanitize ? v.map! { sanitize_sql_like(_1) } : v.map!(&:to_s)
        }.compact!
        dst.rmerge!(term) if term.present?
      end
      dst
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Dynamically create a derived table with JSON fields expanded into columns
    #
    # @param [String, Array, Hash, nil] extra   Passed to #sql_extended_table
    # @param [Hash]                     opt     Passed to #sql_extended_table
    #
    # @return [ActiveRecord::Result]
    #
    def extended_table(extra = nil, **opt)
      sql = sql_extended_table(extra, **opt)
      ActiveRecord::Base.connection.exec_query(sql)
    end

    # Generate the SQL statement for dynamically creating a derived table with
    # JSON fields expanded into columns.
    #
    # @param [String, Array, Hash, nil]    extra      More SQL appended to FROM
    # @param [Hash{Symbol=>Array<Symbol>}] field_map
    # @param [Array<Symbol>, Symbol, nil]  only
    # @param [Array<Symbol>, Symbol, nil]  except
    # @param [Hash]                        where      WHERE clause elements.
    #
    # @return [String]
    #
    def sql_extended_table(
      extra       = nil,
      field_map:, # Must be supplied by the subclass.
      only:       nil,
      except:     nil,
      **where
    )
      if !field_map.is_a?(Hash)
        Log.warn do
          "#{self.class}.#{__method__}: " \
          "field_map: #{field_map.class} instead of Hash"
        end
        field_map = {}
      elsif only || except
        only         = Array.wrap(only).map(&:to_sym)
        except       = Array.wrap(except).map(&:to_sym)
        field_map = field_map.slice(*only)    if only.present?
        field_map = field_map.except(*except) if except.present?
      end
      table_alias = field_map.map { |col, _| [col, "#{col}_columns"] }.to_h

      opt =
        Array.wrap(extra).flatten.map { |v|
          if v.is_a?(Hash)
            where = v.deep_symbolize_keys.merge!(where)
            next
          end
          v.presence
        }.compact
      clause = where.presence && sql_where_clause(**where)
      opt.prepend("WHERE #{clause}") if clause.present?
      opt = opt.join(' ')

      json_tables =
        field_map.map { |col, json_fields|
          sql_json_table(col, fields: json_fields, name: table_alias[col])
        }.join(', ')

      columns_to_show =
        field_names.map { |col|
          (name = table_alias[col]) ? "#{name}.*" : "#{table_name}.#{col}"
        }.join(', ')

      "SELECT #{columns_to_show} FROM #{table_name}, #{json_tables} #{opt};"
    end

  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Class methods automatically added to the including class.
  #
  module ClassMethods

    include InstanceMethods

    # Non-functional hints for RubyMine type checking.
    # :nocov:
    unless ONLY_FOR_DOCUMENTATION
      include ActiveRecord::ModelSchema::ClassMethods
      include ActiveRecord::QueryMethods
    end
    # :nocov:

    # =========================================================================
    # :section: InstanceMethods overrides
    # =========================================================================

    public

    # The fields defined in the schema for this record.
    #
    # @return [Array<Symbol>]
    #
    def field_names
      @field_names ||= (columns_hash.keys.map(&:to_sym) rescue [])
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Build a relation for finding records with columns containing matches on
    # the given search term(s).
    #
    # @param [Array<Hash,String>]               terms
    # @param [Symbol, String, Hash, Array, nil] sort    Implicit sort if *nil*.
    # @param [Hash]                             opt     Passed to #sql_match.
    #
    # @return [ActiveRecord::Relation]
    #
    def matching(*terms, sort: nil, **opt)
      where(sql_match(*terms, **opt)).tap do |relation|
        relation.order!(sort) if sort
      end
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    return unless Record.record_class?(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

end

__loading_end(__FILE__)
