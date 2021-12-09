# app/controllers/concerns/search_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/search" controller.
#
module SearchConcern

  extend ActiveSupport::Concern

  include ApiConcern
  include EngineConcern
  include PaginationConcern
  include SearchCallConcern

  include LayoutHelper
  include SearchHelper

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include PaginationConcern
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the EMMA Unified Search API service.
  #
  # @return [SearchService]
  #
  def search_api
    engine = requested_engine(SearchService)
    # noinspection RubyMismatchedReturnType
    engine ? SearchService.new(base_url: engine) : api_service(SearchService)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # index_search
  #
  # @param [Boolean] titles           If *false*, get records not titles.
  # @param [Boolean] save             If *false*, do not save search terms.
  # @param [Boolean] scores           Calculate experimental relevancy scores.
  # @param [Symbol]  items            Specify method for #pagination_finalize.
  # @param [Boolean] canonical        Passed to SearchTitleList#initialize.
  # @param [Hash]    opt              Passed to SearchService#get_records.
  #
  # @return [Search::Message::SearchRecordList]
  # @return [Search::Message::SearchTitleList]    If :titles is *true*.
  #
  # == Usage Notes
  # If :titles is *true* then :canonical defaults to *true* on the production
  # service and *false* everywhere else.
  #
  def index_search(
    titles:    true,
    save:      true,
    scores:    false,
    items:     nil,
    canonical: nil,
    **opt
  )
    save_search(**opt)                   if save
    list = search_api.get_records(**opt)
    list.calculate_scores!(**opt)        if scores
    flash_now_alert(list.exec_report)    if list.error?
    if titles
      canonical = production_deployment? if canonical.nil?
      list = Search::Message::SearchTitleList.new(list, canonical: canonical)
      items ||= :titles
    else
      items ||= :records
    end
    pagination_finalize(list, items, **opt)
    list
  end

  # index_record
  #
  # @param [Hash] **opt
  #
  # @return [Search::Message::SearchRecord]
  #
  # @see SearchService::Request::Records#get_record
  #
  def index_record(**opt)
    search_api.get_record(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether search calls should be recorded by default.
  #
  # @type [Boolean]
  #
  SAVE_SEARCHES = true?(ENV.fetch('SAVE_SEARCHES', true))

  # Indicate whether the current search should be recorded.
  #
  # @param [User, nil] user           Default: `#current_user`.
  #
  def save_search?(user = nil)
    SAVE_SEARCHES # TODO: criteria?
  end

  # Record a search call.
  #
  # @param [User, nil]    user        Default: `#current_user`.
  # @param [Array, #to_a] result      Default: @list.
  # @param [Boolean]      force       Save even if #save_search? is *false*.
  # @param [Hash]         parameters  Default: `#search_call_params`.
  #
  # @return [SearchCall]              New record.
  # @return [nil]                     If saving was not possible.
  #
  def save_search(user: nil, result: nil, force: false, **parameters)
    user ||= current_user
    return unless force || save_search?(user)
    attr = search_call_params(parameters)
    attr[:controller] ||= :search
    attr[:action]     ||= :index
    attr[:user]       ||= user
    attr[:result]     ||= result || @list
    # noinspection RubyMismatchedReturnType
    SearchCall.create(attr)
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

  public

  # Analyze the *list* object to generate the path for the next page of
  # results.
  #
  # @param [Search::Message::SearchTitleList, Array<Search::Record::MetadataRecord>, nil] list
  # @param [Hash, nil] url_params     Current request parameters.
  #
  # @return [String]                  Path to generate next page of results.
  # @return [nil]                     If there is no next page.
  #
  # @see PaginationConcern#next_page_path
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def next_page_path(list: nil, **url_params)
    items = list.try(:records) || list || page_items
    return if (items.size < page_size) || (last = items.last).blank?

    # General pagination parameters.
    opt    = url_parameters(url_params)
    page   = positive(opt.delete(:page))
    offset = positive(opt.delete(:offset))
    limit  = positive(opt.delete(:limit))
    size   = limit || page_size
    if offset && page
      offset = nil if offset == ((page - 1) * size)
    elsif offset
      page   = (offset / size) + 1
      offset = nil
    else
      page ||= 1
    end
    opt[:page]   = page   + 1    if page
    opt[:offset] = offset + size if offset
    opt[:limit]  = limit         if limit && (limit != default_page_size)

    # Parameters specific to the Unified Search API.
    title = date = nil
    case opt[:sort]&.to_sym
      when :title               then title = last.dc_title
      when :sortDate            then date  = last.emma_sortDate
      when :publicationDate     then date  = last.emma_publicationDate
      when :lastRemediationDate then date  = last.rem_remediationDate
      else                           opt.except!(:prev_id, :prev_value)
    end
    if title || date
      opt[:prev_id]    = url_escape(last.emma_recordId)
      opt[:prev_value] = url_escape(title || IsoDay.cast(date))
    end

    make_path(request.path, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Eliminate values from keys that would be problematic when rendering the
  # hash as JSON or XML.
  #
  # @param [*] value
  #
  # @return [*]                       Same type as *value*.
  #
  def sanitize_keys(value)
    if value.is_a?(Hash)
      value
        .transform_keys   { |k| k.to_s.downcase.tr('^a-z0-9_', '_') }
        .transform_values { |v| sanitize_keys(v) }
    elsif value.is_a?(Array) && (value.size > 1)
      value.map { |v| sanitize_keys(v) }
    elsif value.is_a?(Array)
      sanitize_keys(value.first)
    elsif value.is_a?(String) && value.include?(FileFormat::FILE_FORMAT_SEP)
      value.split(FileFormat::FILE_FORMAT_SEP).compact_blank
    else
      value
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the argument contains only valid identifiers.
  #
  # @param [String, Array<String>] value
  #
  def valid_identifiers?(value)
    ids = PublicationIdentifier.objects(value)
    ids.present? && ids.all? { |id| id&.valid? }
  end

  # Indicate whether the argument contains only valid identifiers and provide
  # a list of individual validation problems.
  #
  # @param [String, Array<String>] value
  #
  # @return [Hash]
  #
  def validate_identifiers(value)
    ids    = []
    errors = []
    PublicationIdentifier.object_map(value).each_pair do |term, id|
      if id&.valid?
        ids << id.to_s
      elsif id
        errors << "#{id.to_s.inspect} is not a valid #{id.type.upcase}" # TODO: I18n
      else
        errors << "#{term.inspect} is not a standard identifier" # TODO: I18n
      end
    end
    { valid: errors.blank?, ids: ids, errors: errors}
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Extract the URL parameter which specifies an index record.
  #
  # @return [String]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :recordId found.
  #
  def set_record_id
    @record_id = params[:record_id] || params[:recordId] || params[:id]
  end

  # Re-cast URL parameters which are aliases for :identifier and redirect to
  # the modified URL if found.
  #
  # @return [void]
  #
  def identifier_alias_redirect
    opt     = request_parameters
    aliases = opt.extract!(*PublicationIdentifier.identifier_types)
    return if aliases.blank?
    opt[:identifier] = aliases.map { |type, term| "#{type}:#{term}" }.join(' ')
    redirect_to opt
  end

  # Translate an identifier query to a keyword query if the search term does
  # not look like a valid identifier.
  #
  # @return [void]
  #
  def invalid_identifier_redirect
    opt = request_parameters
    return if opt[:q].present?
    return if (identifier = opt[:identifier]).blank?
    return if PublicationIdentifier.cast(identifier)
    opt[:q] = identifier.sub(/^[^:]+:/, '')
    redirect_to opt.except!(:identifier)
  end

  # Translate a keyword query for an identifier into an identifier query.
  # For other query types, queries that include a standard identifier prefix
  # (e.g. "isbn:...") are re-cast as :identifier queries.
  #
  # @return [void]
  #
  def identifier_keyword_redirect
    opt = request_parameters
    search_query_keys(**opt).find do |q_param|
      next if (q_param == :identifier) || (query = opt[q_param]).blank?
      next unless (identifier = PublicationIdentifier.cast(query))
      opt[:identifier] = identifier.to_s
      redirect_to opt.except!(q_param)
    end
  end

  # Process the URL parameter for setting the immediate searches.
  #
  def set_immediate_search
    opt = request_parameters
    return unless opt.key?(:immediate_search)
    if true?(opt.delete(:immediate_search))
      session['app.search.immediate'] = 'true'
    else
      session.delete('app.search.immediate')
    end
    redirect_to opt
  end

  # Process the URL parameter for setting the search engine URL.
  #
  def set_search_engine
    set_engine_callback(SearchService)
  end

  # Process the URL parameter for setting the search style.
  #
  def set_search_style
    opt   = request_parameters
    style = session['app.search.style'].presence
    if (in_params = opt.key?(:style))
      value = opt.delete(:style)&.strip&.downcase
      if value.blank? || ApiService::RESET_KEYS.include?(value.to_sym)
        style = nil
      elsif LayoutHelper::SearchFilters::SEARCH_STYLES.include?(value.to_sym)
        style = value
      else
        Log.warn("#{__method__}: invalid style #{value.inspect}")
      end
    end
    if style
      session['app.search.style'] = style
    else
      session.delete('app.search.style')
    end
    redirect_to opt if in_params
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    # In order to override #next_page_path this must be...
    included_after(base, PaginationConcern, this: THIS_MODULE)

  end

end

__loading_end(__FILE__)
