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

  # Non-facet search fields.
  #
  # @type [Array<Symbol>]
  #
  TEXT_SEARCH_PARAMETERS = %i[q].freeze

  # URL parameters that are definitely not search parameters.
  #
  # @type [Array<Symbol>]
  #
  NON_SEARCH_KEYS = %i[offset start limit api_key].freeze

  # Term separator for #list_search_terms.
  #
  # @type [String]
  #
  LIST_SEARCH_SEPARATOR = ' | '

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Active search terms.
  #
  # The result is ordered such that text-only (query) fields(s) come before
  # facet selection fields.
  #
  # @param [Hash{Symbol=>String}]  pairs    Default: `#url_parameters`.
  # @param [Symbol, Array<Symbol>] only
  # @param [Symbol, Array<Symbol>] except
  #
  # @return [Hash{Symbol=>SearchTerm}]
  #
  def search_terms(pairs: nil, only: nil, except: nil)
    only    = Array.wrap(only).presence
    except  = Array.wrap(except) + NON_SEARCH_KEYS
    pairs &&= pairs.dup if only || except
    pairs ||= url_parameters
    pairs.slice!(*only)    if only
    pairs.except!(*except) if except
    # noinspection RubyYardParamTypeMatch
    term_list = pairs.map { |f, values| [f, SearchTerm.new(f, values)] }.to_h
    queries, filters = partition_options(term_list, *TEXT_SEARCH_PARAMETERS)
    queries.merge!(filters)
  end

  # A control displaying the currently-applied search terms in the current
  # scope (by default).
  #
  # @param [Hash{Symbol=>SearchTerm}, nil] term_list  Default: `#search_terms`.
  # @param [Hash]      opt            Passed to the innermost :content_tag
  #                                     except for:
  #
  # @option opt [Integer] :row        Display row (default: 1)
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def applied_search_terms(term_list, **opt)
    opt, term_opt = partition_options(opt, :row)
    term_list ||= search_terms
    queries, facets = partition_options(term_list, *TEXT_SEARCH_PARAMETERS)
    queries.reject! { |_, v| v.null_search? }
    row = positive(opt[:row]) || 1

    # The label prefixing the list of active search terms.
    ld_opt = { class: 'label' }
    append_css_classes!(ld_opt, 'query') if facets.blank?
    i18n_path = %w(search_controls _self)
    i18n_path << (queries.blank? ? 'facet_only' : 'label')
    leader = i18n_lookup(search_type, i18n_path)
    leader = content_tag(:div, leader, ld_opt)

    # The list of active search terms.
    # noinspection RubyYardParamTypeMatch
    list = render_applied_search_terms(term_list, **term_opt)

    # The active search term element.
    html_opt = { class: "applied-search-terms row-#{row}" }
    if list.blank?
      append_css_classes!(html_opt, 'invisible') if list.blank?
    else
      list = content_tag(:div, class: 'search-terms') { leader << list }
    end
    content_tag(:div, list, html_opt)
  end

  # Produce a text-only listing of search terms.
  #
  # @param [Hash{Symbol=>SearchTerm}] term_list   Default: `#search_terms`.
  # @param [String]                   separator
  #
  # @return [String]
  #
  def list_search_terms(term_list, separator: LIST_SEARCH_SEPARATOR)
    term_list ||= search_terms
    term_list.map { |field, search_term|
      next if search_term.blank?
      if search_term.query?
        array_string(search_term.names, quote: true)
      else
        +"#{field}: " << array_string(search_term.values)
      end
    }.compact.join(separator)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Render a set of search term labels and values.
  #
  # @param [Hash{Symbol=>SearchTerm}] term_list
  # @param [Hash] opt                 Passed to enclosing #content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_applied_search_terms(term_list, **opt)
    base_opt  = prepend_css_classes(opt, 'term')
    separator = content_tag(:div, '/', class: 'term-separator')
    # @type [Symbol]     _field
    # @type [SearchTerm] search_term
    term_list.map { |_field, search_term|
      next if search_term.blank? || search_term.null_search?
      part = {}
      if (query = search_term.query?)
        part[:value]     = render_search_term_text(search_term)
      else
        part[:field]     = search_term.label
        part[:separator] = ':'
        part[:value]     = render_search_term_badge(search_term)
      end
      opt = append_css_classes(base_opt, (query ? 'query' : 'facet'))
      content_tag(:div, opt) do
        part.map { |k, v| content_tag(:div, v, class: k) }.join.html_safe
      end
    }.compact.join(separator).html_safe
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
      content_tag(:div, quote(v), class: 'text')
    }.join(separator).html_safe
  end

  # Render a search term value as a badge with a removal control.
  #
  # @param [SearchTerm] search_term
  # @param [String]     separator     Default: #LIST_SEPARATOR.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_search_term_badge(search_term, separator: LIST_SEPARATOR)
    search_term.pairs.map { |value, label|
      label   = content_tag(:div, label, class: 'text')
      control = remove_search_term_button(search_term.parameter, value)
      content_tag(:div, class: 'badge') { label << control }
    }.join(separator).html_safe
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
    opt[:'aria-role'] ||= 'button'
    opt[:title]       ||= 'Click to remove this search limiter' # TODO: I18n
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

end

__loading_end(__FILE__)
