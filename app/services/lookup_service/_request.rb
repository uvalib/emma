# app/services/lookup_service/_request.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A collection of identifiers and/or search terms.
#
# === Implementation Notes
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

  # The format of a request object.
  #
  # @type [Hash]
  #
  # @see file:app/assets/javascripts/channels/lookup-channel.js *REQUEST_TYPE*
  #
  TEMPLATE = {
    request: {
      ids:   [],
      query: [],
      limit: []
    },
  }.deep_freeze

  DEFAULT_QUERY = 'keyword'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [Hash]
  attr_reader :table

  # Create a new instance.
  #
  # @param [LookupService::Request, Hash, Array, String, nil] items
  #
  def initialize(items = nil)
    @table = TEMPLATE.deep_dup
    return if items.blank?
    # noinspection RubyMismatchedArgumentType
    if items.is_a?(self.class)
      @table.merge!(items.deep_dup)
    elsif items.is_a?(Hash)
      items = items[:request] || items.slice(*TEMPLATE[:request].keys)
      @table[:request].merge!(items.deep_dup)
    else
      @table[:request].merge!(ids: items.deep_dup)
    end
    @table[:request].each_pair do |k, v|
      if k == :ids
        v.replace(id_list(v.map! { |term| fix_term(term) }))
      else
        v.map! { |term| fix_term(term, author: term.start_with?('author:')) }
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All search term elements.
  #
  # @return [Array<String,PublicationIdentifier>]
  #
  def values
    request.values.flatten
  end

  # All search terms in "prefix:value" format.
  #
  # @return [Array<String>]
  #
  def terms
    values.map(&:to_s)
  end

  # add_term
  #
  # @param [PublicationIdentifier, String, Symbol, nil] prefix
  # @param [String, nil]                                value
  # @param [Hash]                                       opt   To #fix_term.
  #
  # @return [PublicationIdentifier, String, nil]
  #
  def add_term(prefix, value = nil, **opt)
    prefix, value = [nil, prefix] if value.nil?
    return if prefix.blank? && value.blank?
    if value.is_a?(PublicationIdentifier)
      term = nil
      id   = value
    else
      if prefix.present?
        term = fix_term("#{prefix}:#{value}", **opt)
        type = prefix.to_sym
      else
        term = fix_term(value, **opt)
        type = term.sub(/:.*$/, '').to_sym
      end
      id =
        if PublicationIdentifier.identifier_types.include?(type)
          PublicationIdentifier.cast(term, invalid: true)
        end
    end
    if id
      request[:ids] = [*request[:ids], id]
    else
      request[:query] = [*request[:query], term]
    end
    id || term
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Remove quotes surround a term and provide a prefix if needed.
  #
  # @param [PublicationIdentifier, String, nil] term
  # @param [Boolean, Array<String>]             author
  #
  # @return [PublicationIdentifier, String, nil]
  #
  def fix_term(term, author: false, **)
    return term unless term.is_a?(String)
    value = term.strip

    # Strip quote mistakenly surrounding the whole term.
    value.sub!(/^(["'])\s*(.*)\s*\1$/, '\2')

    # Extract the query type prefix.
    value.sub!(/^([^:]+)\s*:\s*/, '')
    prefix = $1&.presence&.downcase || DEFAULT_QUERY

    # Strip surrounding quotes from the query term.
    value.sub!(/^(["'])\s*(.*)\s*\1$/, '\2')

    # Strip date from author name if requested.
    author = author.include?(prefix) if author.is_a?(Array)
    value.sub!(/\s*,?\s*(\[.*\]|\(.*\)|\d+.*\d+|\d+-?)$/, '') if author

    "#{prefix}:#{value}"
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
    table[:request]
  end

  # The identifiers involved in this request.
  #
  # @return [Array<PublicationIdentifier>]
  #
  def identifiers
    request[:ids]
  end

  # The identifier types involved in this request.
  #
  # @return [Array<Symbol>]
  #
  def id_types
    identifiers.map(&:type).uniq
  end

  # Present the entire request structure as a Hash.
  #
  # @return [Hash]
  #
  def to_h
    table.compact
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  def dup
    self.class.new(self)
  end

  def deep_dup
    self.class.new(self)
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

  protected

  # Create a serializer for this class and any subclasses derived from it.
  #
  # @param [Class] this_class
  #
  # @see Serializer::Base#serialize?
  #
  def self.make_serializers(this_class)
    this_class.class_exec do

      serializer :serialize do |instance|
        instance.to_h
      end

      serializer :deserialize do |hash|
        new(re_symbolize_keys(hash))
      end

      def self.inherited(subclass)
        make_serializers(subclass)
      end

    end
  end

  make_serializers(self)

end

__loading_end(__FILE__)
