# app/controllers/concerns/search_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/search" controller.
#
module SearchConcern

  extend ActiveSupport::Concern

  include FlashHelper
  include ParamsHelper
  include SearchModesHelper
  include SearchTermsHelper

  include ApiConcern
  include EngineConcern
  include PaginationConcern
  include SearchCallConcern

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

  # @private
  GENERATE_SCORES = false

  # index_search
  #
  # @param [Boolean] titles           If *false*, return records not titles.
  # @param [Boolean] save             If *false*, do not save search terms.
  # @param [Boolean] scores           Calculate experimental relevancy scores.
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
  def index_search(titles: nil, save: true, scores: nil, canonical: nil, **opt)

    titles = title_results? if titles.nil?
    scores = search_debug?  if scores.nil? && GENERATE_SCORES

    save_search(**opt)      if save

    list = search_api.get_records(**opt)
    if list.error?
      flash_now_alert(list.exec_report)
    elsif scores
      list.calculate_scores!(**opt)
    end

    if titles
      canonical = production_deployment? if canonical.nil?
      Search::Message::SearchTitleList.new(list, canonical: canonical)
    else
      list
    end
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
    # noinspection RubyMismatchedReturnType
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
  # @param [User, nil] _user          Default: `#current_user`.
  #
  def save_search?(_user = nil)
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
  # @note Currently unused.
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
  # @return [void]
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
  # @return [void]
  #
  def set_search_engine
    set_engine_callback(SearchService)
  end

  # Process the URL parameter for setting the search results type (i.e.,
  # title-level display or file-level display).
  #
  # @param [Symbol, String, nil] type
  #
  # @return [void]
  #
  # == Usage Notes
  # Either run manually or as a controller action, the method will update
  # `session['app.search.style']`.  In the latter case, if *style* is taken
  # from the URL parameter a redirect will occur.
  #
  def set_search_results(type = nil)
    valid_values = SearchModesHelper::SEARCH_RESULTS
    set_search_feature(:results, type, valid_values, meth: __method__)
  end

  # Process the URL parameter for setting the search style.
  #
  # @param [Symbol, String, nil] style
  #
  # @return [void]
  #
  # == Usage Notes
  # Either run manually or as a controller action, the method will update
  # `session['app.search.style']`.  In the latter case, if *style* is taken
  # from the URL parameter a redirect will occur.
  #
  def set_search_style(style = nil)
    valid_values = SearchModesHelper::SEARCH_STYLES
    set_search_feature(:style, style, valid_values, meth: __method__)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  private

  # set_search_feature
  #
  # @param [Symbol]               param_key
  # @param [*]                    value
  # @param [Array<Symbol>,Symbol] valid_values
  # @param [String]               session_key
  # @param [Symbol]               meth
  #
  # @return [void]
  #
  def set_search_feature(
    param_key,
    value,
    valid_values,
    session_key: nil,
    meth:        __method__
  )
    valid_values  = Array.wrap(valid_values)
    session_key ||= "app.search.#{param_key}"
    opt = nil
    if value.nil?
      if (prm = request_parameters).key?(param_key)
        opt   = prm
        value = opt.delete(param_key).presence
      else
        value = session[session_key].presence
      end
    end
    if (value &&= value.to_s.strip.presence&.underscore&.to_sym)
      # noinspection RubyMismatchedArgumentType
      if EngineConcern::RESET_KEYS.include?(value)
        value = nil
      elsif !valid_values.include?(value)
        Log.warn("#{meth}: invalid #{param_key} value '#{value}'")
        return
      end
    end
    if value
      session[session_key] = value.to_s
    else
      session.delete(session_key)
    end
    redirect_to opt if opt && !false?(opt[:redirect])
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

  protected

  # Create a Paginator for the current controller action.
  #
  # @param [Class<Paginator>] paginator  Paginator class.
  # @param [Hash]             opt        Passed to super.
  #
  # @return [SearchPaginator]
  #
  def pagination_setup(paginator: SearchPaginator, **opt)
    # noinspection RubyMismatchedReturnType
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
