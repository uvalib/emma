# app/services/lookup_service/_request.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A collection of identifiers transformed into PublicationIdentifier and
# grouped by type.
#
# == Implementation Notes
# This class can't be implemented as a subclass of Hash because the ActiveJob
# serializer will fail to distinguish it from a simple Hash (and thereby fail
# to engage its custom serializer/deserializer).
#
class LookupService::Request

  include LookupService::Common

  include Serializable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash]
  TEMPLATE = {
    request: {
      ids:   {},
      query: [],
      limit: []
    },
  }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [Hash]
  attr_reader :table

  # Create a new instance.
  #
  # @param [LookupService::Request, Hash, Array, String, *] items
  #
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedArgumentType
  #++
  def initialize(items)
    # noinspection RubyMismatchedVariableType
    @table = TEMPLATE.deep_dup
    if items.is_a?(self.class)
      @table.merge!(items.deep_dup)
    elsif !items.is_a?(Hash)
      @table[:request][:ids] = items
    elsif items.key?(:request)
      items = items[:request]
      @table[:request].merge!(items.deep_dup) if items.present?
    else
      items = items.slice(*TEMPLATE[:request].keys)
      @table[:request].merge!(items.deep_dup) if items.present?
    end
    TEMPLATE[:request].except(:ids).each_key do |k|
      v = @table[:request][k]
      @table[:request][k] = v.is_a?(Hash) ? v.values : Array.wrap(v)
    end
    fix_ids!
    fix_query!
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Re-build the list of identifier "prefix:value" terms into a table keyed
  # by the prefix.
  #
  # @return [void]
  #
  def fix_ids!
    return if (ids = @table[:request][:ids]).blank?
    @table[:request][:ids] = id_hash(ids)
  end

  # Observation has indicated some quirks that need to be addresses by
  # massaging "author:" queries:
  #
  # * WorldCat can handle "King, Stephen" but not "King,Stephen".
  # * Google Books can handle "Stephen King" but not "King, Stephen".
  # * WorldCat can handle either.
  #
  # @return [void]
  #
  def fix_query!
    return if @table[:request][:query].blank?
    @table[:request][:query].map! do |term|
      # Determine the query type prefix and remove it.
      term = term.dup
      term.sub!(/^([^:]+):/, '')
      prefix = $1

      # Strip surrounding quotes from the query term.
      term.sub!(/^(["'])(.*)\1$/, '\2')
      quote = $1

      # If this is an author query like "King, Stephen", get the last name and
      # move it to the end.
      if (prefix == 'author') && term.include?(',')
        given_name = term.sub!(/^([^,]+),\s*/, '')
        last_name  = $1
        term = "#{given_name} #{last_name}"
      end

      # Prepare to add surrounding quotes if needed and not already provided.
      if term.gsub!(/[[:space:][:punct:]]+/, ' ')
        term.strip!
        quote ||= %q(")
      end

      # Reconstruct the full query term.
      term = "#{quote}#{term}#{quote}" if quote
      term = "#{prefix}:#{term}"       if prefix
      term
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Identifiers to lookup grouped by type.
  #
  # @return [Hash{Symbol=>*}]
  #
  def request
    # noinspection RubyMismatchedReturnType
    table[:request]
  end

  # Identifiers to lookup grouped by type.
  #
  # @return [Hash{Symbol=>Array<PublicationIdentifier>}]
  #
  def request_ids
    request[:ids] || {}
  end

  # The identifier types involved in this request.
  #
  # @return [Array<Symbol>]
  #
  def id_types
    request_ids.keys
  end

  # The identifiers involved in this request.
  #
  # @return [Array<PublicationIdentifier>]
  #
  def identifiers
    request_ids.values.flatten
  end

  # Present the entire request structure as a Hash.
  #
  # @return [Hash]
  #
  def to_h
    table.compact
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new instance from *item* if it is not already an instance.
  #
  # @param [LookupService::Request, *] item
  #
  # @return [LookupService::Request]
  #
  def self.wrap(item)
    item.is_a?(self) ? item : new(item)
  end

  # ===========================================================================
  # :section: LookupService::Request::Serializer
  # ===========================================================================

  public

  serializer :serialize do |item|
    item.to_h
  end

  serializer :deserialize do |value|
    re_symbolize_keys(value)
  end

end

__loading_end(__FILE__)
