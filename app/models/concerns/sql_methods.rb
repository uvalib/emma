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

  # Translate hash keys/values into SQL conditions.
  #
  # @param [Array<Hash,String>]  terms
  # @param [String, Symbol, nil] connector  Either :or or :and; default: :and
  # @param [String, Symbol, nil] join       Alias for :connector.
  # @param [Hash]                other      Additional terms.
  #
  # @return [String]  SQL expression.
  # @return [Array]   SQL clauses if *connector* is set to *nil*.
  #
  # == Examples
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
  def sql_terms(*terms, join: :and, connector: join, **other)
    connector = connector.to_s.strip.upcase unless connector.nil?
    terms << other if other.present?
    terms.flatten!
    terms.compact!
    result =
      terms.map { |term|
        term = sql_clauses(term, join: connector)  if term.is_a?(Hash)
        term.start_with?('(') ? term : "(#{term})" if term.present?
      }.compact
    connector ? result.join(" #{connector} ") : result
  end

  # Translate hash keys/values into SQL conditions.
  #
  # @param [Hash]           hash
  # @param [String, Symbol, nil] connector  Either :or or :and; default: :and
  # @param [String, Symbol, nil] join       Alias for :connector.
  #
  # @return [String]  SQL expression.
  # @return [Array]   SQL clauses if *connector* is set to *nil*.
  #
  # == Examples
  #
  # @example AND-ed values
  #   sql_clauses(id: '123', age: '18') -> "id = '123' AND age = '18'"
  #
  # @example OR-ed values
  #   sql_clauses(id: '123', age: '18', join: :or)-> "id = '123' OR age = '18'"
  #
  def sql_clauses(hash, join: :and, connector: join)
    connector = connector.to_s.strip.upcase unless connector.nil?
    result    = hash.map { |k, v| sql_clause(k, v) }
    connector ? result.join(" #{connector} ") : result
  end

  # Translate a key and value into a SQL condition.
  #
  # @param [String, Symbol, Hash] k
  # @param [Any]                  v
  #
  # @return [String]
  #
  #--
  # == Variations
  #++
  #
  # @overload sql_clause(k, v)
  #   @param [String, Symbol] k
  #   @param [Any]            v
  #
  # @overload sql_clause(hash)
  #   @param [Hash] hash              Only the first pair is used.
  #
  # == Examples
  #
  # @example Single value
  #   sql_clause(:id, '123') -> "id = '123'"
  #
  # @example Single value as a hash
  #   sql_clause(id: '123')  -> "id = '123'"
  #
  # @example Multiple values
  #   sql_clause(:id, %w(123 456 789)) -> "id IN ('123','456','789')"
  #
  # @example Multiple values as a hash
  #   sql_clause(id: %w(123 456 789))  -> "id IN ('123','456','789')"
  #
  def sql_clause(k, v = nil)
    k, v = *k.first        if k.is_a?(Hash)
    v = Array.wrap(v)      if v.is_a?(Range)
    v = v.strip            if v.is_a?(String)
    v = v.split(/\s*,\s*/) if v.is_a?(String) && v.include?(',')
    v = v.uniq             if v.is_a?(Array)
    if v.is_a?(Array)
      if (v.size > 1) && (v.map(&:class).uniq.size == 1)
        ranges = v.sort.chunk_while { |prev, this| prev.succ == this }.to_a
        ranges.map! { |r| (r.size >= 5) ? Range.new(r.first, r.last) : r }
        ranges, singles = ranges.partition { |r| r.is_a?(Range) }
        ranges.map! do |range|
          first, last = range.minmax.map { |s| sql_quote(s) }
          "#{k} BETWEEN #{first} AND #{last}"
        end
      else
        ranges  = []
        singles = v
      end
      if singles.present?
        singles.flatten!
        singles.map! { |s| sql_quote(s) }
        ranges << "#{k} IS NULL"                     if singles.reject!(&:nil?)
        ranges << "#{k} IN (%s)" % singles.join(',') if singles.present?
      end
      # noinspection RubyMismatchedReturnType
      if ranges.size > 1
        ranges.map! { |s| "(#{s})" }.join(' OR ')
      else
        ranges.first
      end
    elsif (v = sql_quote(v))
      "#{k} = #{v}"
    else
      "#{k} IS NULL"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Look for a value in a standard database field.
  #
  # @param [Symbol, String] column
  # @param [String]         text
  # @param [Boolean]        exact
  # @param [Boolean]        match_case
  #
  # == Usage Notes
  # Does not handle "match_case: true".
  #
  def sql_match_pattern(column, text, exact: false, match_case: false)
    Log.warn { "#{__method__}: match_case not implemented" } if match_case
    value   = sql_json_pattern(text, exact: exact)
    exact   = true unless value.is_a?(String)
    matches = exact ? '=' : 'LIKE'
    "(#{column} #{matches} #{value})"
  end

  # Look for value in a JSON-type database column.
  #
  # @param [Symbol, String] column
  # @param [String, #to_s]  text
  # @param [Boolean]        exact
  # @param [Boolean]        match_case
  #
  # @see https://dev.mysql.com/doc/refman/8.0/en/json-function-reference.html
  # @see https://stackoverflow.com/questions/49782240/can-i-do-case-insensitive-search-with-json-extract-in-mysql
  #
  # == Usage Notes
  # Does not handle "exact: false" for field names yet, only field values.
  #
  def sql_match_json(column, text, exact: false, match_case: false)

    # JSON_CONTAINS(json_doc, candidate[, path])
    # JSON_CONTAINS_PATH(json_doc, 'one'|'all', path[, path, ...])
    # JSON_EXTRACT(json_doc, path[, path, ...])
    # JSON_KEYS(json_doc[, path])
    # JSON_OVERLAPS(json_doc1, json_doc2)
    # JSON_SEARCH(json_doc, 'one'|'all', search_str[, esc_char[, path, ...]])
    # JSON_VALUE(json_doc, path)

    key, value =
      if text.is_a?(String) && text.include?(':')
        text.split(':', 2)
      else
        [nil, text]
      end

    if key.blank?
      pattern = sql_json_pattern(value, exact: exact, match_case: match_case)
      "(JSON_SEARCH(#{column}, 'one', #{pattern}) IS NOT NULL)"

    elsif (value = value&.to_s&.strip).blank? || (value == '*')
      Log.warn { "#{__method__}: field match is always exact" } unless exact
      "JSON_CONTAINS_PATH(#{column}, '$.#{key}')"

    else
      # function = match_case ? "#{column}->'$.#{key}'" : "CAST(#{column}->>'$.#{key}' AS CHAR)"
      function = "JSON_EXTRACT(#{column}, '$.#{key}')"
      function = "CAST(JSON_UNQUOTE(#{function}) AS CHAR)" unless match_case
      sql_match_pattern(function, value, exact: exact, match_case: match_case)
    end
  end

  # Prepare a string for matching.
  #
  # @param [String, Any] text
  # @param [Boolean]     exact
  # @param [Boolean]     match_case
  #
  # @return [String, Any]
  #
  def sql_json_pattern(text, exact: false, match_case: false)
    if text.is_a?(String) || text.is_a?(Symbol)
      text = text.to_s.strip
      if digits_only?(text)
        text = text.to_i
      elsif digits_only?(text.delete('.'))
        text = text.to_f
      end
    end
    return text unless text.is_a?(String)
    text = "%#{text}%" unless exact || text.match?(/^[%_]|[^\\][%_]/)
    match_case ? "'#{text}'" : "CAST('#{text}' AS CHAR)"
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
  # == Implementation Notes
  # * Documentation indicates that '$[*]' should work but only '$' seems to.
  #
  def sql_json_table(column, name: nil, fields: nil, field_map: nil)
    alias_name   = name   || "#{column}_columns"
    # noinspection RubyMismatchedArgumentType
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
  #--
  # noinspection RubyNilAnalysis
  #++
  def sql_where_clause(field_map: nil, param_map: nil, **matches)
    fm_valid    = field_map.is_a?(Hash)
    pm_valid    = param_map.is_a?(Hash)
    json_fields = fm_valid && pm_valid
    unless json_fields || (!field_map && !param_map)
      error = []
      error << 'have field_map but missing param_map' if fm_valid && !param_map
      error << 'have param_map but missing field_map' if pm_valid && !field_map
      field_map = nil if fm_valid
      param_map = nil if pm_valid
      error << "field_map: #{field_map.class} instead of Hash" if field_map
      error << "param_map: #{param_map.class} instead of Hash" if param_map
      error.each { |err| Log.warn { "#{self.class}.#{__method__}: #{err}" } }
    end
    matches.map { |field, match|
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
        Log.warn { "#{__method__}: ignoring invalid field #{field.inspect}" }
        next
      end
      match = match.strip if match.is_a?(String)
      match = true        if true?(match)
      match = false       if false?(match)
      condition =
        case match
          when Array                    then 'IN (%s)' % quote(match)
          when true                     then '= TRUE'
          when false                    then '= FALSE'
          when nil, /^nil$/i, /^NULL$/i then 'IS NULL'
          when '*', /^ANY$/i            then 'IS NOT NULL'
          when /^[<>=!]+\s*\d+$/        then "#{match}"
          when String                   then "LIKE '%#{match}%'"
          when Symbol                   then "= '#{match}'"
          else                               "= #{match}"
        end
      "(#{name} #{condition})"
    }.compact.join(' AND ')
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
    name.join('_').presence&.gsub(/\d/) { |d| DIGIT_TO_ALPHA[d] || '_' }
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
  # @param [Integer, Float, String, Symbol, nil]
  #
  # @return [Integer, Float, String, nil]
  #
  def sql_quote(value)
    case value
      when Integer, Float           then value
      when nil, /^nil$/i, /^NULL$/i then nil
      when /^\d+$/                  then value.to_i
      when /^-?(\.\d+|\d+\.\d*)$/   then value.to_f
      else                               "'#{value}'"
    end
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
    # @param [Array<Hash,String>]  terms
    # @param [String, Symbol, nil] connector  Either :or or :and; default: :and
    # @param [String, Symbol, nil] join       Alias for :connector.
    # @param [Hash]                opt        Passed to #merge_match_terms.
    #
    # @return [String]  SQL expression.
    # @return [Array]   SQL clauses if *connector* is set to *nil*.
    #
    def sql_match(*terms, join: :and, connector: join, **opt)
      opt[:columns] &&= Array.wrap(opt[:columns]).compact.map(&:to_sym).presence
      opt[:columns] ||= field_names
      matcher = (opt[:type] == :json) ? :sql_match_json : :sql_match_pattern
      result =
        merge_match_terms(*terms, **opt).flat_map do |field, matches|
          matches.map { |text| send(matcher, field, text) }
        end
      connector ? result.join(' %s ' % connector.to_s.strip.upcase) : result
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
    # @param [Boolean]             sanitize   If *false* do not escape '%', '_'
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
      columns &&= field_names.select { |f| columns.include?(f) }
      columns ||= field_names
      terms.flatten!
      terms.compact!
      terms.each do |term|
        term =
          if term.is_a?(Hash)
            term.deep_symbolize_keys
          else
            columns.map { |col| [col, term] }.to_h
          end
        term.transform_values! do |v|
          v = Array.wrap(v).compact_blank.map!(&:to_s)
          v.map! { |s| sanitize_sql_like(s) } if sanitize
          v.presence
        end
        term.compact!
        dst.rmerge!(term)
      end
      dst
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Dynamically create a derived table with JSON fields expanded into columns
    #
    # @param [String, Hash, nil] extra  Passed to #sql_extended_table
    # @param [Hash]              opt    Passed to #sql_extended_table
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
    # @param [String, Hash, nil]           extra      More SQL appended to FROM
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

      options =
        Array.wrap(extra).flatten.map { |v|
          if v.is_a?(Hash)
            where = v.deep_symbolize_keys.merge!(where)
            next
          end
          v.presence
        }.compact
      clause = where.presence && sql_where_clause(**where)
      options << "WHERE #{clause}" if clause.present?
      options = options.join(' ')

      json_tables =
        field_map.map { |column, json_fields|
          sql_json_table(column, fields: json_fields, name: table_alias[column])
        }.join(', ')

      columns_to_show =
        field_names.map { |column|
          (name = table_alias[column]) ? "#{name}.*" : "#{table_name}.#{column}"
        }.join(', ')

      "SELECT #{columns_to_show} FROM #{table_name}, #{json_tables} #{options};"
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
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::ModelSchema::ClassMethods
      include ActiveRecord::QueryMethods
      # :nocov:
    end

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
      # noinspection RubyMismatchedReturnType
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
    base.send(:include, InstanceMethods)
    base.send(:extend,  ClassMethods)
  end

end

__loading_end(__FILE__)
