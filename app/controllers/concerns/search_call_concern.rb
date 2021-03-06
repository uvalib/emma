# app/controllers/concerns/search_call_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/search_call" controller.
#
module SearchCallConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'SearchCallConcern')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  SC_PARAMETERS = (
    SearchCall.field_names + SearchCall::PARAMETER_MAP.keys - %i[id]
  ).sort.uniq.freeze

  # Columns searched for generic (:like) matches.
  #
  # @type [Array<Symbol>]
  #
  SC_MATCH_COLUMNS = SearchCall::JSON_COLUMNS

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Only allow a list of trusted parameters through. # TODO: strong params
  #
  # @param [ActionController::Parameters, Hash, nil] p   Default: `params`.
  #
  # @return [Hash]
  #
  def search_call_params(p = nil)
=begin
    params.require(:search_call).permit!
    # noinspection RubyYardReturnMatch
    params.fetch(:search_call, {})
=end
    url_parameters(p).slice(*SC_PARAMETERS)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get matching SearchCall records or all records if no terms are given.
  #
  # @param [Array<String,Hash,Array>]    terms
  # @param [Array, nil]                  columns      Def.: #SC_MATCH_COLUMNS
  # @param [Symbol, String, Hash, Array] sort         Def.: :created_at
  # @param [Hash]                        hash_terms   Added to *terms*.
  #
  # @option opt [Symbol, String, Hash, (Symbol, Hash)] :sort  Default: :id
  #
  # @return [ActiveRecord::Relation<SearchCall>]
  #
  def get_search_calls(*terms, columns: nil, sort: :created_at, **hash_terms)
    terms.flatten!
    terms.map! { |t| t.is_a?(Hash) ? t.deep_symbolize_keys : t if t.present? }
    terms.compact!
    terms << hash_terms if hash_terms.present?
    if terms.blank?
      SearchCall.all.order(sort)
    else
      columns ||= SC_MATCH_COLUMNS
      SearchCall.matching(*terms, columns: columns, type: :json, sort: sort)
    end
  end

end

__loading_end(__FILE__)
