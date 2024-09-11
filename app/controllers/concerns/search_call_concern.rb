# app/controllers/concerns/search_call_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/search_call" controller.
#
module SearchCallConcern

  extend ActiveSupport::Concern

  include ParamsHelper

  include SerializationConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  SC_PARAMETERS =
    (SearchCall.field_names + SearchCall::PARAMETER_MAP.keys)
      .excluding(:id).sort.uniq.deep_freeze

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
    # noinspection RubyMismatchedReturnType
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
  # @param [Symbol, String, Hash, Array] sort         Def.: implicit order
  # @param [Hash]                        hash_terms   Added to *terms*.
  #
  # @return [ActiveRecord::Relation<SearchCall>]
  #
  def get_search_calls(*terms, columns: nil, sort: nil, **hash_terms)
    terms.flatten!
    terms.compact_blank!
    terms.map! { _1.is_a?(Hash) ? _1.deep_symbolize_keys : _1 }
    terms << hash_terms if hash_terms.present?
    if terms.blank?
      relation = SearchCall.all
    else
      columns ||= SC_MATCH_COLUMNS
      relation = SearchCall.matching(*terms, columns: columns, type: :json)
    end
    sort ? relation.order(sort) : relation
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [SearchCall, Hash] item
  # @param [Hash]             opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def show_values(item = @item, **opt)
    if item.is_a?(SearchCall)
      item = item.as_search_parameters
    else
      item = item.to_h.deep_symbolize_keys
    end
    opt.reverse_merge!(name: :search_call)
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
