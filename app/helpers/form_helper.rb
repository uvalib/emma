# app/helpers/form_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the creation of forms.
#
module FormHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a hidden '<input>' which indicates a parameter for the new search
  # URL that will result from the associated facet value being removed from the
  # current search.
  #
  # @param [Symbol, String]      k
  # @param [String, Array, nil]  v
  # @param [Symbol, String, nil] id
  # @param [String]              separator
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def hidden_input(k, v, id: nil, separator: "\n")
    id = [id, k].compact_blank!.join('-')
    if v.is_a?(Array)
      v.map.with_index(1) { |value, index|
        hidden_field_tag("#{k}[]", value, id: "#{id}-#{index}")
      }.join(separator).html_safe
    else
      # noinspection RubyMismatchedReturnType
      hidden_field_tag(k, v, id: id)
    end
  end

  # Create sets of hidden fields to accompany the *id* field.
  #
  # The field names are sorted so that the method returns zero or more
  # '<input type="hidden">' elements which should be inserted before the *id*
  # field and zero or more elements that should be inserted after.
  #
  # This ensures that the resulting search URL will be generated with
  # parameters in a consistent order.
  #
  # @param [Symbol, String, nil] id
  # @param [Hash]                fields
  #
  # @return [Array(Array,Array)]
  #
  def hidden_parameters_for(id, fields)
    id    = id&.to_sym
    skip  = [id, *Paginator::NON_SEARCH_KEYS].compact
    pairs = fields.symbolize_keys.except!(*skip).compact_blank!.sort
    before_after = id ? pairs.partition { |k, _| k <= id } : [pairs, []]
    before_after.each { |a| a.map! { |k, v| hidden_input(k, v, id: id) } }
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
