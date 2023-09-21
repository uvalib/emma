# app/decorators/searches_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/search" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Search::Record::MetadataRecord>,Array<Search::Record::TitleRecord>]
#
class SearchesDecorator < BaseCollectionDecorator

  # Because the test environment is not eager-loaded, these variants need to be
  # explicitly loaded.
  #
  if Rails.env.test?
    require_relative 'search_title_decorator'
    require_relative 'search_record_decorator'
  end

  # This causes automated testing to slow down too much, so related server-side
  # and client-side code is neutralized in the test environment.
  #
  # @type [Boolean]
  #
  SEARCH_ANALYSIS = !Rails.env.test?

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of SearchDecorator

  # ===========================================================================
  # :section: BaseCollectionDecorator::List overrides
  # ===========================================================================

  public

  # Controls for applying one or more search style variants.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # @see #STYLE_BUTTONS
  # @see SearchModesHelper#permitted_by?
  # @see file:javascripts/feature/search-analysis.js *AdvancedFeature*
  #
  def list_styles(css: STYLE_CONTAINER, **opt)
    trace_attrs!(opt)
    b_opt   = trace_attrs_from(opt).merge(class: 'style-button')
    buttons =
      STYLE_BUTTONS.values.map { |prop|
        next unless permitted_by?(prop[:active])
        button_opt = b_opt.merge(title: prop[:tooltip])
        prepend_css!(button_opt, prop[:class])
        html_button(prop[:label], **button_opt)
      }.compact
    return unless buttons.present?
    prepend_css!(opt, css)
    html_div(buttons, **opt)
  end if SEARCH_ANALYSIS

  # Control for selecting the type of search results to display.
  #
  # @param [String,Symbol,nil] selected  Selected menu item.
  # @param [String]            css       Characteristic CSS class/selector.
  # @param [Hash]              opt       Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #RESULT_TYPES
  # @see SearchModesHelper#results_type
  # @see SearchModesHelper#permitted_by?
  # @see file:app/assets/javascripts/controllers/search.js *$mode_menu*
  #
  def list_results(selected: nil, css: '.results.single.menu-control', **opt)
    base_path  = request_value(:path)
    url_params = param_values.except(*RESULT_IGNORED_PARAMS)
    results    = url_params.delete(:results)
    selected ||= results || results_type
    default    = nil
    pairs =
      RESULT_TYPES.map { |type, prop|
        next unless permitted_by?(prop[:active])
        default = type if prop[:default]
        [prop[:label], type]
      }.compact
    opt[:'data-path'] = make_path(base_path, **url_params)
    prepend_css!(opt, css)
    trace_attrs!(opt)
    html_div(**opt) do
      menu_name   = :results
      option_tags = h.options_for_select(pairs, selected)
      select_opt  = { id: unique_id(menu_name) }
      select_opt[:title]          = 'Search results output mode' # TODO: I18n
      select_opt[:'aria-label']   = select_opt[:title]
      select_opt[:'data-default'] = default if default
      h.select_tag(menu_name, option_tags, select_opt)
    end
  end

end

__loading_end(__FILE__)
