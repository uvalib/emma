# app/helpers/search_terms_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting processing and display of search terms.
#
module SearchTermsHelper

  def self.included(base)
    __included(base, '[SearchTermsHelper]')
  end

  include Emma::Common
  include Emma::Json
  include Emma::Unicode

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Query string which indicates a "null search".
  #
  # @type [String]
  #
  NULL_SEARCH = '*'

  # EMMA Unified Search types.
  #
  # Each entry may have:
  #
  #   :label          Label for the menu selection.
  #   :tooltip        Tooltip for the menu selection.
  #   :placeholder    Placeholder text to display in the search input box.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  SEARCH_TYPE = I18n.t('emma.search_type').deep_freeze

  # Non-facet search fields.
  #
  # @type [Array<Symbol>]
  #
  QUERY_PARAMETERS = SEARCH_TYPE.keys.freeze

  # URL parameters that are definitely not search parameters.
  #
  # @type [Array<Symbol>]
  #
  NON_SEARCH_KEYS = %i[offset start limit api_key modal].freeze

  # Term separator for #list_search_terms.
  #
  # @type [String]
  #
  LIST_SEARCH_SEPARATOR = ' | '

  # URL parameters related to search menu settings.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_KEYS = %i[keyword sort limit language]

  # URL parameters related to search sort menu settings.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_SORT_KEYS = %i[sortOrder direction]

  # Controllers which supply their own search capabilities.
  #
  # @type [Array<Symbol>]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  SEARCH_CONTROLLERS =
    I18n.t('emma.application.search_controllers').map(&:to_sym).freeze

  # The search controller that should be used on any pages whose controllers
  # do not provide their own search capability.
  #
  # @type [Symbol]
  #
  DEFAULT_SEARCH_CONTROLLER = SEARCH_CONTROLLERS.first

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The current type of search (as indicated by the current controller).
  #
  # @param [Hash, Symbol, String, nil] type   Default: `#params[:controller]`.
  #
  # @return [Symbol]                    The controller used for searching.
  # @return [nil]                       If searching should not be enabled.
  #
  def search_target(type = nil)
    type ||= request_parameters[:controller]
    type = type[:controller] if type.is_a?(Hash)
    type&.to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Prepare label/value pairs that can be used with #options_for_select to
  # generate a search type selection menu.
  #
  # @param [String, Symbol] _target_type   *ignored*
  #
  # @return [Array<Array<(String,Symbol)>>]
  #
  def search_menu_pairs(_target_type = nil)
    SEARCH_TYPE.map do |type, config|
      label = config[:name] || type.to_s.camelize
      [label, type]
    end
  end

  # Active query parameters.
  #
  # @param [Hash{Symbol=>*}] prm   Default: `#url_parameters`.
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def search_parameters(prm = nil)
    prm ||= url_parameters
    prm.slice(*QUERY_PARAMETERS).transform_values { |v| Array.wrap(v) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Active search terms.
  #
  # The result is ordered such that text-only (query) fields(s) come before
  # facet selection fields.
  #
  # @param [Hash{Symbol=>String,Array}] pairs   Default: `#url_parameters`.
  # @param [Symbol, Array<Symbol>]      only
  # @param [Symbol, Array<Symbol>]      except
  #
  # @return [Hash{Symbol=>SearchTerm}]
  #
  def search_terms(pairs: nil, only: nil, except: nil)
    only   = Array.wrap(only).compact.uniq.presence
    except = [*except, *NON_SEARCH_KEYS].compact.uniq.presence
    pairs  = (only || except) && pairs&.dup || url_parameters
    pairs.slice!(*only)    if only
    pairs.except!(*except) if except
    # noinspection RubyYardParamTypeMatch
    term_list = pairs.map { |f, values| [f, SearchTerm.new(f, values)] }.to_h
    queries, filters = partition_options(term_list, *QUERY_PARAMETERS)
    queries.merge!(filters)
  end

  # Produce a text-only listing of search terms.
  #
  # @param [Hash{Symbol=>SearchTerm}, nil] term_list  Default: `#search_terms`.
  #
  # @option term_list [String] :separator   Default: #LIST_SEARCH_SEPARATOR.
  #
  # @return [String]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def list_search_terms(term_list = nil)
    separator = LIST_SEARCH_SEPARATOR
    if term_list.is_a?(Hash) && term_list.key?(:separator)
      separator = term_list[:separator]
      term_list = term_list.except(:separator).presence
    end
    term_list ||= search_terms
    term_list.map { |_field, term|
      next if term.blank?
      if term.query?
        array_string(term.names, quote: true)
      else
        "#{term.label}: " + array_string(term.values, quote: true)
      end
    }.compact.join(separator)
  end

end

__loading_end(__FILE__)
