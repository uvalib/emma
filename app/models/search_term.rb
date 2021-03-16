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
    @parameter = url_param.to_sym
    @query     = query.present?
    config   ||= {}
    @pairs =
      if values.is_a?(Hash)
        # noinspection RubyNilAnalysis
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
    @label = config[:label] || label || labelize(@parameter, @pairs.size)
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
  def facet?
    !@query
  end

  # Indicate whether this search term represents a "null search".
  #
  def null_search?
    query? && names.include?(NULL_SEARCH)
  end

  # Indicate whether this instance is unassociated with any field values.
  #
  def empty?
    pairs.empty?
  end

  # Indicate whether this instance is associated with a single field values.
  #
  def single?
    !multiple?
  end

  # Indicate whether this instance is associated with multiple field values.
  #
  def multiple?
    count > 1
  end

end

__loading_end(__FILE__)
