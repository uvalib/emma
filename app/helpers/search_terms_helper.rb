# app/helpers/search_terms_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting processing and display of search terms.
#
module SearchTermsHelper

  include Emma::Common
  include Emma::Json
  include Emma::Unicode

  include ConfigurationHelper
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Table of search types for each controller.
  #
  # Each entry may have:
  #
  #   :label          Label for the menu selection.
  #   :tooltip        Tooltip for the menu selection.
  #   :placeholder    Placeholder text to display in the search input box.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_TYPE =
    ApplicationHelper::APP_CONTROLLERS.map { |controller|
      opt   = { controller: controller, mode: false }
      entry = config_lookup('search_type', **opt) || {}
      entry.each_pair do |type, config|
        config[:url_param] = config[:url_param]&.to_sym || type
        config[:name]    ||= type.to_s.camelize
      end
      [controller, entry]
    }.to_h.deep_freeze

  # Non-facet search fields per controller.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  QUERY_PARAMETERS =
    SEARCH_TYPE.transform_values { |types|
      types.map { |type, cfg| cfg[:url_param]&.to_sym || type }
    }.freeze

  # URL parameters that are search-related but "out-of-band".
  #
  # @type [Array<Symbol>]
  #
  PAGINATION_KEYS = Paginator::PAGINATION_KEYS

  # URL parameters that are not directly used in searches.
  #
  # @type [Array<Symbol>]
  #
  NON_SEARCH_KEYS = Paginator::NON_SEARCH_KEYS

  # URL parameters that do not represent relevant search result
  # characteristics for #search_terms.
  #
  # @type [Array<Symbol>]
  #
  NON_SEARCH_TERM_KEYS = (NON_SEARCH_KEYS - %i[page]).freeze

  # URL parameters that are not directly used in searches.
  #
  # @type [Array<Symbol>]
  #
  NON_SEARCH_PARAMS = (
    Record::Searchable::SEARCH_RECORDS_OPTIONS + Paginator::NON_SEARCH_KEYS
  ).uniq.freeze

  # Term separator for #list_search_terms.
  #
  # @type [String]
  #
  LIST_SEARCH_SEPARATOR = ' | '

  # URL parameters related to search menu settings.
  #
  # @type [Array<Symbol>]
  #
  # TODO: This may be questionable...
  #
  SEARCH_KEYS = %i[keyword sort limit language prefix]

  # URL parameters related to search sort menu settings.
  #
  # @type [Array<Symbol>]
  #
  SEARCH_SORT_KEYS = %i[sortOrder direction]

  # Controllers which supply their own search capabilities.
  #
  # @type [Hash{Symbol=>String}]
  #
  SEARCH_CONTROLLERS =
    ApplicationHelper::CONTROLLER_CONFIGURATION.transform_values { |config|
      config.dig(:search, :action).presence
    }.compact.deep_freeze

  # The search controller that should be used on any pages whose controllers
  # do not provide their own search capability.
  #
  # @type [Symbol]
  #
  DEFAULT_SEARCH_CONTROLLER = :search

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The current search target (the current controller by default).
  #
  # @param [Hash, Symbol, String, nil] target
  # @param [Hash]                      opt
  #
  # @return [Symbol]                  The controller used for searching.
  # @return [nil]                     If searching should not be enabled.
  #
  def search_target(target = nil, **opt)
    opt = request_parameters if target.blank? && opt.blank?
    case target
      when Hash           then opt.merge!(target.symbolize_keys)
      when Symbol, String then opt[:target] = target.to_sym
    end
    (opt[:target] || opt[:controller])&.to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Prepare label/value pairs that can be used with #options_for_select to
  # generate a search type selection menu.
  #
  # @param [Hash, Symbol, String, nil] target
  # @param [Hash]                      opt      Passed to #search_target.
  #
  # @return [Array<Array<(String,Symbol)>>]
  #
  def search_query_menu_pairs(target = nil, **opt)
    target = search_target(target, **opt)
    types  = SEARCH_TYPE[target] || {}
    types.map do |type, config|
      [config[:name], type]
    end
  end

  # The URL parameters associated with queries for the indicated search target.
  #
  # @param [Hash, Symbol, String, nil] target
  # @param [Hash]                      opt      Passed to #search_target.
  #
  # @return [Array<Symbol>]
  #
  def search_query_keys(target = nil, **opt)
    target = search_target(target, **opt)
    QUERY_PARAMETERS[target] || []
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
  # @param [Hash, Symbol, String, nil]  target  Passed to #search_target.
  # @param [Hash{Symbol=>String,Array}] pairs   Default: `#url_parameters`.
  # @param [Symbol, Array<Symbol>]      only
  # @param [Symbol, Array<Symbol>]      except
  # @param [Hash]                       opt     Passed to #search_target.
  #
  # @return [Hash{Symbol=>SearchTerm}]
  #
  def search_terms(target = nil, pairs: nil, only: nil, except: nil, **opt)
    target = search_target(target, **opt)
    only   = Array.wrap(only).compact.uniq.presence
    except = [*except, *NON_SEARCH_TERM_KEYS].compact.uniq.presence
    pairs  = (only || except) && pairs&.dup || url_parameters
    pairs.slice!(*only)    if only
    pairs.except!(*except) if except
    qcfg = SEARCH_TYPE[target] || {}
    fcfg = LayoutHelper::SearchFilters::SEARCH_PARAMETER_MENU_MAP[target] || {}
    term_list =
      pairs.map { |prm, values|
        st_opt = { config: qcfg[prm] || fcfg[prm] }
        st_opt[:query] = qcfg[prm].present? if st_opt[:config]
        [prm, SearchTerm.new(prm, values, **st_opt)]
      }.to_h
    queries, filters = partition_hash(term_list, *qcfg.keys)
    queries.merge!(filters)
  end

  # Produce a text-only listing of search terms.
  #
  # @param [Hash{Symbol=>*}, nil] term_list  Default: `#search_terms`.
  #
  # @option term_list [String] :separator   Default: #LIST_SEARCH_SEPARATOR.
  #
  # @return [String]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def list_search_terms(term_list = nil)
    separator = LIST_SEARCH_SEPARATOR
    if term_list.is_a?(Hash) && term_list.key?(:separator)
      separator = term_list[:separator]
      term_list = term_list.except(:separator).presence
    end
    term_list ||= search_terms
    term_list.map { |field, term|
      next if term.blank?
      term = SearchTerm.new(field, term) unless term.is_a?(SearchTerm)
      if term.query?
        array_string(term.names, inspect: true)
      else
        "#{term.label}: " + array_string(term.values, inspect: true)
      end
    }.compact.join(separator)
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
