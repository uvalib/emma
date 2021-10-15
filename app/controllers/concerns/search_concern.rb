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
  include SearchCallConcern

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
    if (engine = requested_search_engine)
      SearchService.new(base_url: engine)
    else
      # noinspection RubyMismatchedReturnType
      api_service(SearchService)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL of the user-selected search engine.
  #
  # @return [String, nil]             If different than the default engine.
  #
  def requested_search_engine
    url = SearchService.engine_url(get_session_search_engine)
    url unless url == SearchService.default_engine_url
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of the `session` entry for overriding the default search engine.
  #
  # @type [String]
  #
  SEARCH_ENGINE_SESSION_KEY = 'app.search.engine'

  # @type [String, nil]
  def get_session_search_engine
    session[SEARCH_ENGINE_SESSION_KEY].presence
  end

  # @type [String, nil]
  def set_session_search_engine(new_value)
    if new_value.present?
      session[SEARCH_ENGINE_SESSION_KEY] = new_value.to_s
    else
      clear_session_search_engine && nil
    end
  end

  # @type [String, nil]
  def clear_session_search_engine
    session.delete(SEARCH_ENGINE_SESSION_KEY)
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
  # @param [Array<Search::Record::MetadataRecord>, nil] list
  # @param [Hash, nil] url_params     Current request parameters.
  #
  # @return [String]                  Path to generate next page of results.
  # @return [nil]                     If there is no next page.
  #
  # @see PaginationConcern#next_page_path
  #
  def next_page_path(list: nil, **url_params)
    items = list&.to_a || page_items
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
      when :lastRemediationDate then date  = last.emma_lastRemediationDate
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
    aliases = opt.extract!(*PublicationIdentifier::identifier_types)
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
    return if PublicationIdentifier.cast(identifier).present?
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
      next if (identifier = PublicationIdentifier.cast(query)).blank?
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
  # The engine may be specified by deployment, e.g. "&engine=staging", or by
  # URL (if that URL matches or derives from a SearchService.engines value).
  # If this resolves to the default search engine then
  # session['app.search.engine'] is deleted; otherwise it will be set to a key
  # of SearchService.engines or to an explicit URL if necessary.
  #
  # If no (valid) :engine parameter was supplied, this method evaluates the
  # current value of session['app.search.engine'], and will delete it if
  # appropriate (but without redirecting).
  #
  def set_search_engine
    opt = request_parameters
    val = url = nil
    if (in_params = opt.key?(:engine)) && (val = opt.delete(:engine).presence)
      if ApiService::RESET_KEYS.include?(val.strip.downcase.to_sym)
        val = nil
      elsif (key = SearchService.engine_key(val))
        val = key
      elsif (url = SearchService.engine_url(val))
        val = nil
      else
        val = nil
        Log.warn("#{__method__}: invalid engine #{val.inspect}")
      end
    elsif !in_params && (current = get_session_search_engine)
      if current.include?('/')
        url = current
      else
        val = current
      end
    end
    val = nil if val && (val == SearchService.default_engine_key)
    url = nil if url && (url == SearchService.default_engine_url)
    if set_session_search_engine(val || url)
      url   ||= SearchService.engine_url(val)
      restore = make_path(request.fullpath, engine: 'reset')
      restore = %Q(<a href="#{restore}">[RESTORE DEFAULT]</a>).html_safe
      notice  = ERB::Util.h("SEARCH ENGINE #{url.inspect}  ") << restore
      #flash_now_notice(notice, html: true) # TODO: ExecReport html_safe
      flash.now[:notice] = [*flash.now[:notice], notice]
    end
    redirect_to opt if in_params
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
