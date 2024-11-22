# app/models/search_term.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An object containing information needed for displaying a search term field
# and its values.
#
class SearchTerm

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Query string which indicates a "null search".
  #
  # @type [String]
  #
  NULL_SEARCH = '*'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL parameter associated with this search term.
  #
  # @return [Symbol]
  #
  attr_reader :parameter

  # The label to use for this search term.
  #
  # @return [String]
  #
  attr_reader :label

  # The label/value pairs for each value associated with this search term.
  #
  # @return [Hash{String=>String}]
  #
  attr_reader :pairs

  # Indicates whether this is a query (text-only) search term.
  #
  # @return [Boolean]
  #
  attr_reader :query

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [String, Symbol]           url_param
  # @param [Hash, Array, String, nil] values
  # @param [String, nil]              label
  # @param [Boolean, nil]             query
  # @param [Hash, nil]                config
  #
  def initialize(url_param, values = nil, label: nil, query: nil, config: nil)
    config   ||= {}
    @parameter = url_param.to_sym
    @label     = config[:label] || label
    @query     = query.present?
    @pairs =
      if values.is_a?(Hash)
        values.stringify_keys.transform_values(&:to_s)
      elsif values.present?
        Array.wrap(values).map { |v|
          v = strip_quotes(v)
          term = config[:menu]&.find { |lbl, val| break lbl if val == v }
          term ||= ISO_639.find(v)&.english_name if url_param == :language
          term ||= v
          [v, term]
        }.to_h
      end
    @pairs ||= {}
    @label ||= labelize(@parameter, count: @pairs.size)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return just the field value(s) associated with this instance.
  #
  # @return [Array<String>]
  #
  def values
    pairs.keys
  end

  # Return just the textual descriptions of the field value(s) associated
  # with this instance.
  #
  # @return [Array<String>]
  #
  def names
    pairs.values
  end

  # The number of field values associated with this instance.
  #
  # @return [Integer]
  #
  def count
    pairs.size
  end

  # Indicate whether this is a query (text-only) search term.
  #
  def query?
    @query
  end

  # Indicate whether this search term represents facet value(s).
  #
  # @note Currently unused.
  # :nocov:
  def facet?
    !@query
  end
  # :nocov:

  # Indicate whether this search term represents a "null search".
  #
  # @note Currently unused.
  # :nocov:
  def null_search?
    query? && names.include?(NULL_SEARCH)
  end
  # :nocov:

  # Indicate whether this instance is unassociated with any field values.
  #
  def empty?
    pairs.empty?
  end

  # Indicate whether this instance is associated with a single field values.
  #
  # @note Currently unused.
  # :nocov:
  def single?
    !multiple?
  end
  # :nocov:

  # Indicate whether this instance is associated with multiple field values.
  #
  # @note Currently used only by #single?.
  # :nocov:
  def multiple?
    count > 1
  end
  # :nocov:

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Indicate whether the instance is equivalent to another value.
  #
  # @param [SearchTerm, any, nil] other
  #
  # @return [Boolean]
  #
  def ==(other)
    other.is_a?(self.class) &&
      (parameter == other.parameter) &&
      (label == other.label) &&
      (query == other.query) &&
      (count == other.count) &&
      pairs.all? { |k, v| v == other.pairs[k] if other.pairs.key?(k) }
  end

end

__loading_end(__FILE__)
