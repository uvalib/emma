# app/decorators/search_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base item presenter for "/search" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Search::Record::MetadataRecord, Search::Record::TitleRecord]
#
class SearchDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  set_model_type(:search) # not `decorator_for search: Search::Api::Record`

  # ===========================================================================
  # :section: Definitions shared with SearchesDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BaseDecorator::SharedPathMethods
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include CssHelper

    include BaseDecorator::SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Render a single label/value pair.
    #
    # @param [String, Symbol, nil] label
    # @param [any, nil]            value
    # @param [Hash]                opt        Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    def render_pair(label, value, **opt)
      return if value.blank?
      opt.reverse_merge!(no_code: true)
      super
    end

    # =========================================================================
    # :section: BaseDecorator::Fields overrides
    # =========================================================================

    public

    # The defined levels for rendering an item hierarchically.
    #
    # @param [Hash] opt
    #
    # @return [Hash{Symbol=>Array<Symbol,Integer>}]
    #
    def field_levels(**opt)
      Search::Record::TitleRecord::HIERARCHY_PATHS
    end

    # =========================================================================
    # :section: SearchModesHelper overrides
    # =========================================================================

    public

    # Get the display mode for search results.
    #
    # @return [Symbol]
    #
    def results_type
      context[__method__] || h.send(__method__)
    end

    # Get the display style variant for search results.
    #
    # @return [Symbol]
    #
    def search_style
      context[__method__] || h.send(__method__)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @private
    # @type [Hash]
    SEARCH_CONFIGURATION = config_page_section(:search).deep_freeze

    # CSS class for the colorization button tray.
    #
    # @type [String]
    #
    STYLE_CONTAINER = 'button-tray'

    # Colorization button configuration template.
    #
    # @type [Hash{Symbol=>String,Symbol}]
    #
    STYLE_BUTTON_TEMPLATE = SEARCH_CONFIGURATION.dig(:styles, :_colorize)

    # Colorization buttons.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    STYLE_BUTTONS =
      SEARCH_CONFIGURATION[:styles].map { |style, prop|
        next if style.start_with?('_')
        prop = prop.dup
        prop[:label] ||= style.to_s

        css = prop[:class].presence || STYLE_BUTTON_TEMPLATE[:class]
        css = css_class_array(css)
        css << style if css.include?(STYLE_BUTTON_TEMPLATE[:class])
        prop[:class] = css_classes(css)

        ident   = prop.delete(:ident).presence
        tooltip = prop.delete(:title).presence || prop[:tooltip].presence
        tooltip %= { ident: ident } if tooltip && ident
        prop.delete(:tooltip) if (prop[:tooltip] = tooltip).blank?

        field = prop[:field]
        field = STYLE_BUTTON_TEMPLATE[:field] if false?(field)
        prop.delete(:field) if (prop[:field] = field).nil?

        prop[:enabled] = SearchModesHelper.guard_values(prop[:enabled])

        [style, prop]
      }.compact.to_h.deep_freeze

    # Search result types.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    RESULT_TYPES =
      SEARCH_CONFIGURATION[:results].map { |style, prop|
        next if style.start_with?('_')
        prop = prop.dup
        prop[:label] ||= style.to_s

        tooltip = prop.delete(:title).presence || prop[:tooltip].presence
        prop.delete(:tooltip) if (prop[:tooltip] = tooltip).blank?

        prop[:enabled] = SearchModesHelper.guard_values(prop[:enabled])

        [style, prop]
      }.compact.to_h.deep_freeze

    # Parameters not included in the base path in #search_list_results.
    #
    # @type [Array<Symbol>]
    #
    RESULT_IGNORED_PARAMS =
      (ParamsHelper::IGNORED_PARAMS + Paginator::PAGE_KEYS).uniq.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # In debug mode, add date and volume information to the title line.
    #
    # @type [Boolean]
    #
    SEARCH_EXTENDED_TITLE = true?(ENV_VAR['SEARCH_EXTENDED_TITLE'])

    # Indicate whether items should get extended titles.
    #
    def extended_title?
      SEARCH_EXTENDED_TITLE && search_debug?
    end

    # In debug mode, add a display of the (supposed) relevancy score.
    #
    # @note This is probably not very helpful for `results_type == :title`.
    #
    # @type [Boolean]
    #
    SEARCH_RELEVANCY_SCORE = true?(ENV_VAR['SEARCH_RELEVANCY_SCORE'])

    # Indicate whether items should show relevancy scores.
    #
    def relevancy_scores?
      SEARCH_RELEVANCY_SCORE && search_debug?
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # CSS classes for the current search style.
    #
    # @param [String] suffix
    #
    # @return [Array<String>]
    #
    # @see SearchModesHelper#search_style
    #
    def style_classes(suffix: '-style')
      styles = [search_style]
      styles << :dev if search_debug?
      styles.remove(*ApiService::RESET_KEYS)
      styles.compact_blank!
      styles.map! { _1.end_with?(suffix) ? _1.to_s : "#{_1}#{suffix}" }
    end

    # CSS classes for the current results mode.
    #
    # @param [String] suffix
    #
    # @return [Array<String>]
    #
    # @see SearchModesHelper#results_type
    #
    def result_classes(suffix: '_results')
      results = [results_type]
      results.remove(*ApiService::RESET_KEYS)
      results.compact_blank!
      results.map! { _1.end_with?(suffix) ? _1.to_s : "#{_1}#{suffix}" }
    end

  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module SharedInstanceMethods
    include BaseDecorator::SharedInstanceMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module SharedClassMethods
    include BaseDecorator::SharedClassMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module SharedDefinitions
    def self.included(base)
      base.include(SharedInstanceMethods)
      base.extend(SharedClassMethods)
    end
  end

end

class SearchDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: BaseDecorator::Links overrides
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def link(**opt)
    opt[:path] = search_path(id: object.identifier)
    super
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [any, nil]    value
  # @param [Symbol, nil] field
  # @param [Hash]        opt          Passed to the render method or super.
  #
  # @return [Field::Type]
  # @return [String]
  # @return [nil]
  #
  def list_field_value(value, field:, **opt)
    if present? && field.is_a?(Symbol)
      case field
        when :dc_title                then title_and_source_logo(**opt)
        when :emma_repositoryRecordId then source_record_link(**opt)
        when :emma_retrievalLink      then source_retrieval_link(**opt)
        else                               field_for(field, value: value)
      end
    end || super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Add date and volume information to the title line.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  #--
  # noinspection RubyMismatchedArgumentType, RailsParamDefResolve
  #++
  def extended_title
    date    = Search::Record::TitleRecord.item_date(object).presence
    parts   = object.try(:all_item_numbers, '&thinsp;|&thinsp;'.html_safe)
    parts ||= Search::Record::TitleRecord.item_number(object).presence
    title   = ERB::Util.h(object.full_title)
    title  << html_span(date,  class: 'item-date')   if date
    title  << html_span(parts, class: 'item-number') if parts
    title
  end

  # Display title of the associated work along with the logo of the source
  # repository.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div for title and to
  #                                     #prev_next_controls.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LogoHelper#repository_source_logo
  #
  def title_and_source_logo(css: '.title', **opt)
    score  = relevancy_scores? && relevancy_scores
    title  = extended_title? && extended_title || object.full_title
    source = object.emma_repository
    source = '' unless EmmaRepository.values.include?(source)
    prepend_css!(opt, css, source)

    elements = []
    elements << html_div(title, **opt)
    elements << h.repository_source_logo(source)
    elements << prev_next_controls(**opt)
    elements << score if score.present?
    safe_join(elements)
  end

  # Display title of the associated work along with the source repository.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_div for title and to
  #                                     #prev_next_controls.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LogoHelper#repository_source
  #
  def title_and_source(css: '.title', **opt)
    title  = object.full_title
    source = object.emma_repository
    source = nil unless EmmaRepository.values.include?(source)
    prepend_css!(opt, css, source)
    title  = html_div(title, **opt)
    name   = source&.titleize || 'LOGO'
    logo   = h.repository_source(object, source: source, name: name)
    ctrl   = prev_next_controls(**opt)
    title << logo << ctrl
  end

  # An element containing controls for moving up and down through the list.
  #
  # @param [String] css       Characteristic CSS class/selector.
  # @param [Hash]   opt       Passed to #prev_record_link and #next_record_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def prev_next_controls(css: '.prev-next', **opt)
    html_div(class: css_classes(css)) do
      prev_record_link(**opt) << next_record_link(**opt)
    end
  end

  # Create a control for jumping to the previous record in the list.
  #
  # @param [Integer] index            Current index.
  # @param [String]  css              Characteristic CSS class/selector.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LinkHelper#icon_button
  # @see file:app/assets/javascripts/feature/scroll.js *scrollToPrev()*
  #
  def prev_record_link(index: nil, css: '.prev', **)
    opt = {}
    if (enabled = index && (index > paginator.first_index))
      opt[:icon]     = UP_TRIANGLE
      opt[:title]    = config_term(:search, :record, :prev_tooltip)
      opt[:url]      = '#value-Title-%d' % (index - 1)
    else
      opt[:icon]     = DELTA
      opt[:title]    = config_term(:search, :record, :first_tooltip)
      opt[:tabindex] = -1
    end
    prepend_css!(opt, css)
    append_css!(opt, 'forbidden') unless enabled
    icon_button(**opt)
  end

  # Create a control for jumping to the next record in the list.
  #
  # @param [Integer] index            Current index.
  # @param [String]  css              Characteristic CSS class/selector.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LinkHelper#icon_button
  # @see file:app/assets/javascripts/feature/scroll.js *scrollToNext()*
  #
  def next_record_link(index: nil, css: '.next', **)
    opt = {}
    if (enabled = index && (index < paginator.last_index))
      opt[:icon]     = DOWN_TRIANGLE
      opt[:title]    = config_term(:search, :record, :next_tooltip)
      opt[:url]      = '#value-Title-%d' % (index + 1)
    else
      opt[:icon]     = REVERSE_DELTA
      opt[:title]    = config_term(:search, :record, :last_tooltip)
      opt[:tabindex] = -1
    end
    prepend_css!(opt, css)
    append_css!(opt, 'forbidden') unless enabled
    icon_button(**opt)
  end

  # Make a clickable link to the display page for the title on the originating
  # repository's web site.
  #
  # @param [String] label             Link text (def: :emma_repositoryRecordId)
  # @param [String] url               Overrides `object.record_title_url`.
  # @param [Hash]   opt               Passed to #record_popup or
  #                                     LinkHelper#external_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def source_record_link(label: nil, url: nil, **opt)
    url   ||= object.record_title_url
    repo    = repository_for(url, object)
    return record_popup(**opt)     if EmmaRepository.default?(repo)
    return collection_popup(**opt) if EmmaRepository.collection.include?(repo)
    label ||= CGI.unescape(object.emma_repositoryRecordId)
    return ERB::Util.h(label) unless url
    opt[:title] ||=
      config_term(:search, :source, :link_tooltip, repo: record_src(repo))
    external_link(url, label, **opt)
  end

  # Make a clickable link to retrieve a remediated file.
  #
  # @param [String] url               Overrides `object.record_download_url`.
  # @param [Hash]   opt               Passed to link method except for:
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element.
  # @return [nil]                       If no *url* was provided or found.
  #
  # @see RepositoryHelper#emma_retrieval_link
  # @see BaseDecorator::Download#bv_retrieval_link
  # @see BaseDecorator::Download#ia_retrieval_link
  # @see file:javascripts/feature/download.js *notAuthorizedMessage()*
  #
  def source_retrieval_link(url: nil, **opt)
    url   ||= object.record_download_url.presence or return
    repo    = repository_for(url, object)
    format  = object.dc_format
    opt.merge!(format: format) if %i[ace internetArchive].include?(repo)

    # Adjust the link depending on whether the current session is permitted to
    # perform the download.
    allowed = can?(:download, Upload)
    is_user = !allowed && h.signed_in?
    failure = !allowed && (is_user ? 'role-failure' : 'sign-in-required')
    append_css!(opt, failure) if failure

    # Set up the tooltip to be shown before the item has been requested.
    tooltip =
      if allowed
        fmt = format.to_s.underscore.upcase.tr('_', ' ')
        rep = download_src(repo)
        cpo = { fmt: fmt, repo: rep }
        config_term(:search, :source, :retrieval_tip, **cpo)

      elsif is_user
        fmt = object.label
        rep = repo || EmmaRepository.default
        rol = current_user&.role&.capitalize
        cpo = { fmt: fmt, repo: rep, role: rol }
        config_page(:download, :link, :role_failure, :tooltip, **cpo)

      else
        fmt = object.label
        rep = repo || EmmaRepository.default
        cpo = { fmt: fmt, repo: rep }
        config_page(:download, :link, :sign_in, :tooltip, **cpo)
      end
    opt[:'data-forbid'] ||= tooltip unless allowed
    opt[:title]         ||= tooltip

    case repo&.to_s
      when 'emma'             then emma_retrieval_link(url, **opt)
      when 'ace'              then ace_retrieval_link( url, **opt)
      when 'internetArchive'  then ia_retrieval_link(  url, **opt)
      when 'openAlex'         then oa_retrieval_link(  url, **opt)
      when /^bibliovault/i    then bv_retrieval_link(  url, **opt)
      else Log.error { "#{__method__}: #{repo.inspect}: unexpected" } if repo
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a metadata listing of a search result item.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details(**opt)
    opt[:pairs] ||= model_show_fields
    super
  end

  # details_container
  #
  # @param [Array] before             Optional elements before the details.
  # @param [Hash]  opt                Passed to super except:
  #
  # @option opt [Symbol, Array<Symbol>] :skip   Display aspects to avoid.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_container(*before, **opt, &blk)
    skip = Array.wrap(opt.delete(:skip))
    before.prepend(cover(placeholder: false)) unless skip.include?(:cover)
    super
  end

  # Create a container with the repository ID displayed as a link but acting as
  # a popup toggle button and a popup panel which is initially hidden.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To PopupHelper#inline_popup except:
  #
  # @option opt [Hash] :attr          Options for deferred content.
  # @option opt [Hash] :placeholder   Options for transient placeholder.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/shared/modal-base.js *ModalBase.toggleModal()*
  #
  def record_popup(css: '.record-popup', **opt)
    p_opt  = opt.delete(:placeholder)
    attr   = opt.delete(:attr)&.dup || {}
    rid    = object.emma_repositoryRecordId
    css_id = opt[:'data-iframe'] || attr[:id] || "record-frame-#{rid}"

    opt[:'data-iframe'] = attr[:id] = css_id
    opt[:title]          ||= config_term(:search, :popup, :tooltip)
    opt[:control]        ||= {}
    opt[:control][:text] ||= ERB::Util.h(rid)

    prepend_css!(opt, css)
    inline_popup(**opt) do
      p_opt = prepend_css(p_opt, 'iframe', POPUP_DEFERRED_CLASS)
      p_opt[:'data-attr'] ||= attr.to_json
      p_opt[:'data-path'] ||= record_popup_path(id: rid)
      p_txt = p_opt.delete(:text) || config_term(:search, :popup, :placeholder)
      html_div(p_txt, **p_opt)
    end
  end

  # Create a popup for displaying the details of a collection item.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #record_popup.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def collection_popup(css: '.collection', **opt)
    p_opt = opt[:placeholder]&.except!(:text) || {}
    p_opt[:'data-path'] ||= record_popup_path(record: collection_popup_data)
    opt[:placeholder] = p_opt
    opt[:title] ||= config_term(:search, :popup, :collection)
    prepend_css!(opt, css)
    record_popup(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The endpoint path for generating content to display within #record_popup.
  #
  # @param [Hash] opt                 Passed to UploadDecorator#show_path.
  #
  # @return [String]
  #
  def record_popup_path(**opt)
    opt[:id] ||= object.emma_repositoryRecordId
    UploadDecorator.show_path(**opt, modal: true)
  end

  # Produce data fields for use with #collection_popup.
  #
  # @param [Hash]
  #
  def collection_popup_data(**opt)
    object.to_h.merge(opt).compact_blank!
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item(**opt)
    trace_attrs!(opt, __method__)
    score_data  = (score_values.presence if relevancy_scores?)
    opt[:outer] = (opt[:outer] || {}).merge(score_data) if score_data
    opt.reverse_merge!(wrap: PAIR_WRAPPER)
    super
  end

  # Include control icons below the entry number.
  #
  # @param [Boolean] toggle           If *true* add item toggle.
  # @param [Boolean] controls         If *true* add edit controls.
  # @param [Hash]    opt              Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item_number(toggle: false, controls: false, **opt)
    return ''.html_safe if blank?

    opt[:inner] = nil if opt[:inner].is_a?(TrueClass)
    opt[:inner] = Array.wrap(opt[:inner]).dup
    opt[:outer] = Array.wrap(opt[:outer]).dup

    item_id = opt.delete(:id)
    if (toggle &&= list_item_toggle(row: opt[:row], id: item_id))
      opt[:inner] << toggle # Visible for narrow screens.
      opt[:outer] << toggle # Visible for wide and medium-width screens.
      opt[:outer].prepend(format_counts) if search_debug?
    end

    if (controls &&= edit_controls)
      opt[:inner] << controls
    end

    super(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate inline edit controls for the search entry.
  #
  # @param [Symbol] type
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def edit_controls(type: Field::DEFAULT_MODEL)
    if (decorator = ModelTypeMap.get(type))
      decorator.controls_for(object, context: context)
    else
      Log.warn("#{__method__}: no decorator for model type #{type.inspect}")
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate an element to display a score for the item.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def relevancy_scores
    scores = object.try(:get_scores).presence or return
    scores.compact!
    types = scores.keys.map { _1.to_s.delete_suffix('_score') }
    types = [types[...-1].join(', '), types[-1]].compact_blank!.join(' and ')
    tip   = +'This is a guess at the relevancy "score" for this item'
    tip  << " based on its #{types} metadata" if types.present?
    tip  << '.'
    score = scores.values.sum.round
    html_span(score, class: 'item-score', title: tip)
  end

  # Values supporting search result analysis of relevancy scoring.
  #
  # @return [Hash]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def score_values
    return {} if blank?
    {
      'data-normalized_title': object.try(:normalized_title),
      'data-sort_date':        object.try(:emma_sortDate),
      'data-pub_date':         object.try(:emma_publicationDate),
      'data-rem_date':         object.try(:rem_remediationDate),
      'data-item_score':       object.try(:total_score, precision: 2),
    }
  end

  # Generate a summary of the number of files per each format associated with
  # this item.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to outer :ul.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def format_counts(css: '.format-counts', **opt)
    prepend_css!(opt, css)
    html_ul(**opt) do
      counts = object&.get_format_counts || {}
      counts.map do |format, count|
        html_li do
          count  = html_span(count, class: 'count')
          format = format.try(:titleize).try(:upcase) || '???'
          format = 'AUDIO' if format == 'DAISY AUDIO'
          format = html_span(format, class: 'format')
          count << format
        end
      end
    end
  end

end

__loading_end(__FILE__)
