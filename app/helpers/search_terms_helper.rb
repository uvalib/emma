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

=begin # TODO: remove eventually
  # A control displaying the currently-applied search terms in the current
  # scope (by default).
  #
  # @param [Hash{Symbol=>SearchTerm}, nil] term_list  Default: `#search_terms`.
  # @param [Hash]      opt            Passed to #render_applied_search_terms
  #                                     except for:
  #
  # @option opt [Integer] :row        Display row (default: 1)
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def applied_search_terms(term_list, **opt)
    opt, term_opt = partition_options(opt, :row)
    term_list ||= search_terms
    queries, facets = partition_options(term_list, *QUERY_PARAMETERS)
    queries.reject! { |_, v| v.null_search? }
    mode = queries.blank? ? :facet_only : :label
    row  = positive(opt[:row]) || 1

    # The label prefixing the list of active search terms.
    ld_opt = { class: 'label' }
    append_css_classes!(ld_opt, 'query') if facets.blank?
    leader = i18n_lookup(search_target, "search_terms.#{mode}")
    leader = html_div(leader, ld_opt)

    # The list of active search terms.
    # noinspection RubyYardParamTypeMatch
    list = render_applied_search_terms(term_list, **term_opt)

    # The active search term element.
    html_opt = { class: "applied-search-terms row-#{row}" }
    if list.blank?
      append_css_classes!(html_opt, 'invisible')
    else
      list = html_div(class: 'search-terms') { leader << list }
    end
    html_div(list, html_opt)
  end
=end

  # Produce a text-only listing of search terms.
  #
  # @param [Hash{Symbol=>SearchTerm}, nil] term_list  Default: `#search_terms`.
  #
  # @option term_list [String] :separator   Default: #LIST_SEARCH_SEPARATOR.
  #
  # @return [String]
  #
  def list_search_terms(term_list = nil)
    separator = LIST_SEARCH_SEPARATOR
    if term_list.is_a?(Hash) && term_list.key?(:separator)
      separator = term_list[:separator]
      term_list = term_list.except(:separator).presence
    end
    term_list ||= search_terms
    term_list.map { |field, search_term|
      next if search_term.blank?
      if search_term.query?
        array_string(search_term.names, quote: true)
      else
        "#{field}: " + array_string(search_term.values)
      end
    }.compact.join(separator)
  end

=begin # TODO: remove eventually
  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Render a set of search term labels and values.
  #
  # @param [Hash{Symbol=>SearchTerm}] term_list
  # @param [Hash] opt                 Passed to enclosing #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_applied_search_terms(term_list, **opt)
    opt = prepend_css_classes(opt, 'term')
    sep = html_div('/', class: 'term-separator')
    term_list.map { |_field, search_term|
      next if search_term.blank? || search_term.null_search?
      classes = []
      section = {}
      if search_term.query?
        classes << 'query'
        section[:value]     = render_search_term_text(search_term)
      else
        classes << 'facet'
        section[:field]     = search_term.label
        section[:separator] = ':'
        section[:value]     = render_search_facet(search_term)
      end
      classes << 'single' if search_term.single?
      html_div(append_css_classes(opt, classes)) do
        section.map { |k, v| html_div(v, class: k) }.join.html_safe
      end
    }.compact.join(sep).html_safe
  end

  # Render a search term value a quoted search terms.
  #
  # @param [SearchTerm] search_term
  # @param [String]     separator     Default: #LIST_SEPARATOR.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_search_term_text(search_term, separator: LIST_SEPARATOR)
    search_term.pairs.values.map { |v|
      html_div(quote(v), class: 'text')
    }.join(separator).html_safe
  end

  # Render one or more facet values as badges.
  #
  # @param [SearchTerm] search_term
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_search_facet(search_term)
    search_term.pairs.map { |value, label|
      # noinspection RubyYardParamTypeMatch
      render_search_term_badge(search_term.parameter, value, label)
    }.join.html_safe
  end

  # Render a search term value as a badge with a removal control.
  #
  # @param [Symbol]      field        URL parameter.
  # @param [String]      value
  # @param [String, nil] label
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_search_term_badge(field, value, label = nil)
    label ||= value.to_s
    label   = html_div(label, class: 'text')
    control = remove_search_term_button(field, value)
    html_div(class: 'badge') { label << control }
  end

  # remove_search_term_button
  #
  # @param [Symbol]        field      URL parameter.
  # @param [String, Array] value      Value(s) to remove from *field*.
  # @param [Hash]          opt        Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def remove_search_term_button(field, value, **opt)
    old_params = url_parameters
    old_value  = normalize_parameter(old_params[field])
    new_value  = old_value - normalize_parameter(value)
    new_value  = new_value.first unless new_value.size > 1
    new_params =
      if new_value.blank?
        old_params.except(field)
      else
        old_params.merge!(field => new_value)
      end
    opt = prepend_css_classes(opt, 'control')
    opt[:role]  ||= 'button'
    opt[:title] ||= 'Click to remove this search limiter' # TODO: I18n
    link_to(HEAVY_X, url_for(new_params), opt)
  end

  # Normal a parameter value for comparison.
  #
  # @param [String, Array] value
  #
  # @return [Array<String>]
  #
  def normalize_parameter(value)
    Array.wrap(value).map { |v| CGI.unescape(v.to_s) }.reject(&:blank?)
  end
=end

end

__loading_end(__FILE__)
