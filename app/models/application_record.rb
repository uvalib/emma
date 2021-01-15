# app/models/artifact.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for database record models.
#
class ApplicationRecord < ActiveRecord::Base

  self.abstract_class = true

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Two records match if their contents are the same.
  #
  # @param [ApplicationRecord, *] other
  #
  def match?(other)
    self.class.match?(self, other)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Find records with fields containing matches on the given search terms.
  #
  # @param [Array<Hash,String>]  terms
  # @param [Hash]                opt    Passed to #sql_match.
  #
  # @return [ActiveRecord::Relation]
  #
  def self.matching(*terms, **opt)
    where(sql_match(*terms, **opt))
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The fields defined in the schema for this record.
  #
  # @return [Array<Symbol>]
  #
  def self.field_names
    columns_hash.keys.map(&:to_sym) rescue []
  end

  # Indicate whether two records match.
  #
  # @param [ApplicationRecord] rec_1
  # @param [ApplicationRecord] rec_2
  #
  def self.match?(rec_1, rec_2)
    (rec_1.is_a?(ApplicationRecord) || rec_2.is_a?(ApplicationRecord)) &&
      (rec_1.class == rec_2.class) &&
      (rec_1.attributes == rec_2.attributes)
  end

  # Translate hash keys/values into SQL conditions.
  #
  # @param [Array<Hash,String>]  terms
  # @param [String, Symbol, nil] connector  Either :or or :and; default: :and.
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
  def self.sql_terms(*terms, join: :and, connector: join, **other)
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
  # @param [String, Symbol, nil] connector  Either :or or :and; default: :and.
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
  def self.sql_clauses(hash, join: :and, connector: join)
    connector = connector.to_s.strip.upcase unless connector.nil?
    result    = hash.map { |k, v| sql_clause(k, v) }
    connector ? result.join(" #{connector} ") : result
  end

  # Translate a key and value into a SQL condition.
  #
  # @param [String, Symbol, Hash] k
  # @param [*, nil]               v
  #
  # @return [String]
  #
  # == Variations
  #
  # @overload sql_clause(k, v)
  #   @param [String, Symbol] k
  #   @param [*]              v
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
  def self.sql_clause(k, v = nil)
    k, v = *k.first if k.is_a?(Hash)
    v = v.strip if v.is_a?(String)
    v = v.split(/\s*,\s*/) if v.is_a?(String) && v.include?(',')
    v = Array.wrap(v).map { |s| "'#{s}'" }.join(',')
    v.include?(',') ? "#{k} IN (#{v})" : "#{k} = #{v}"
  end

  # Translate hash keys/values into SQL LIKE statements.
  #
  # @param [Array<Hash,String>]  terms
  # @param [String, Symbol, nil] connector  Either :or or :and; default: :and.
  # @param [String, Symbol, nil] join       Alias for :connector.
  # @param [Hash]                opt        Passed to #merge_match_terms.
  #
  # @return [String]  SQL expression.
  # @return [Array]   SQL clauses if *connector* is set to *nil*.
  #
  def self.sql_match(*terms, join: :or, connector: join, **opt)
    connector = connector.to_s.strip.upcase unless connector.nil?
    opt[:fields] &&= Array.wrap(opt[:fields]).compact.map(&:to_sym).presence
    opt[:fields] ||= field_names
    result =
      merge_match_terms(*terms, **opt).flat_map do |field, matches|
        matches.map do |string|
          string = "%#{string}%" unless string.match?(/[^\\][%_]/)
          "(#{field} LIKE '#{string}')"
        end
      end
    connector ? result.join(" #{connector} ") : result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Accumulate match pairs.
  #
  # @param [String, Array, Hash] term
  # @param [Hash]                opt    Passed to #merge_match_terms!
  #
  def self.merge_match_terms(*term, **opt)
    merge_match_terms!({}, *term, **opt)
  end

  # Accumulate match pairs.
  #
  # @param [Hash]                dst
  # @param [String, Array, Hash] terms
  # @param [Array<Symbol>]       fields     Limit fields to match.
  # @param [Boolean]             sanitize   If *false* do not escape '%', '_'.
  #
  # @return [Hash{Symbol=>Array<String>}] The modified *dst* hash.
  #
  def self.merge_match_terms!(dst, *terms, fields: nil, sanitize: true, **)
    fields ||= field_names
    terms.flatten!
    terms.compact!
    terms.each do |term|
      term = term.deep_dup                     if term.is_a?(Hash)
      term = fields.map { |f| [f, term] }.to_h unless term.is_a?(Hash)
      term.transform_values! do |v|
        v = Array.wrap(v).reject(&:blank?)
        v.map! { |s| sanitize_sql_like(s) } if sanitize
        v.presence
      end
      term.compact!
      dst.rmerge!(term)
    end
    dst
  end

  # Make a string safe to use within an SQL LIKE statement.
  #
  # @param [String] string
  # @param [String] escape_character
  #
  # @return [String]
  #
  # This method overrides:
  # ActiveRecord::Sanitization::ClassMethods#sanitize_sql_like
  #
  def self.sanitize_sql_like(string, escape_character = '\\')
    string.gsub(/(^|.)([%_])/) do |s|
      ($1 == escape_character) ? s : [$1, escape_character, $2].compact.join
    end
  end

end

__loading_end(__FILE__)
