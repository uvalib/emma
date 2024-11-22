# lib/matomo.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Matomo analytics.
#
# @see https://analytics.lib.virginia.edu
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module Matomo

  include Emma::Common
  include Emma::Constants
  include Emma::Json

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  PROD_SITE = 52
  DEV_SITE  = 53

  def self.id_site = production_deployment? ? PROD_SITE : DEV_SITE

  SITE    = ENV_VAR['ANALYTICS_SITE'] || id_site
  TOKEN   = ENV_VAR['ANALYTICS_TOKEN']
  HOST    = ENV_VAR['ANALYTICS_HOST']
  ROOT    = HOST.start_with?('http') ? HOST : "https://#{HOST}"

  def self.analytics_path(*args, **opt) = make_path(ROOT, *args, **opt)

  SCRIPT  = analytics_path('matomo.js')
  TRACKER = analytics_path('matomo.php')
=begin # TODO: Matomo opt out
  OPT_OUT =
    analytics_path('index.php?module=CoreAdminHome&action=optOut&language=en')
=end

  ENABLED =
    non_test_rails? &&
      ENV_VAR['ANALYTICS_ENABLED'].then do |setting|
        not_deployed? ? true?(setting) : !false?(setting)
      end

  # Default starting range value (to be subtracted from `Date.today`).
  #
  # @type [ActiveSupport::Duration]
  #
  DEFAULT_RANGE = 30.days

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether Matomo analytics are in use.
  #
  # * If not running Rails, always *false*.
  # * If deployed, *true* unless `ENV[ANALYTICS_ENABLED]` is "false".
  # * On the desktop, *false* unless `ENV[ANALYTICS_ENABLED]` is "true".
  #
  def self.enabled? = ENABLED

  # Matomo site identifier ("idSite").
  #
  # The Matomo "site" or "project" is the data collection unit associated with
  # this service.
  #
  # @return [Integer]
  #
  def self.site = SITE

  # Matomo host tracker URL.
  #
  # @return [String]
  #
  def self.tracker_url = TRACKER

  # Matomo script URL.
  #
  # @return [String]
  #
  def self.script_url = SCRIPT

  # Generate a URL to the Matomo analytics dashboard for the current EMMA
  # deployment (or the production deployment on the desktop).
  #
  # @param [Hash] opt                 Passed to #make_path
  #
  # @return [String]
  #
  def self.analytics_url(**opt)
    opt[:date] = :today if opt.values_at(:date, :period).blank?
    date_period!(opt)
    id_site!(opt)
    analytics_path(module: 'CoreHome', action: 'index', **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Used by #analytics_page_url to map API category to the corresponding
  # interactive URL category.
  #
  # @type [Hash{String=>String}]
  #
  #--
  # noinspection RubyStringKeysInHashInspection
  #++
  LIVE_CATEGORY = {
    'Actions'   => 'General_Actions',
    'Goals'     => 'Goals_Goals',
    'Referrers' => 'Referrers_Referrers',
    'Visitors'  => 'General_Visitors',
  }.freeze

  # Used by #analytics_page_url to map API subcategory to the corresponding
  # interactive URL subcategory.
  #
  # @type [Hash{String=>String}]
  #
  #--
  # noinspection RubyStringKeysInHashInspection
  #++
  LIVE_SUBCATEGORY = {
    'All Channels'              => 'Referrers_WidgetGetAll',
    'Devices'                   => 'DevicesDetection_Devices',
    'Downloads'                 => 'General_Downloads',
    'Engagement'                => 'VisitorInterest_Engagement',
    'Entry pages'               => 'Actions_SubmenuPagesEntry',
    'Exit pages'                => 'Actions_SubmenuPagesExit',
    'Locations'                 => 'UserCountry_SubmenuLocations',
    'Outlinks'                  => 'General_Outlinks',
    'Overview'                  => 'General_Overview',
    'Page titles'               => 'Actions_SubmenuPageTitles',
    'Pages'                     => 'General_Pages',
    'Performance'               => 'PagePerformance_Performance',
    'Search Engines & Keywords' => 'Referrers_SubmenuSearchEngines',
    'Software'                  => 'DevicesDetection_Software',
    'Times'                     => 'VisitTime_SubmenuTimes',
    'User IDs'                  => 'UserId_UserReportTitle',
  }.freeze

  # Generate a URL to a specific Matomo analytics page for the current EMMA
  # deployment (or the production deployment on the desktop).
  #
  # @param [Hash] opt                 Passed to #analytics_url except:
  #
  # @option opt [String] :category
  # @option opt [String] :subcategory
  # @option opt [String] :segment
  #
  # @return [String]
  #
  def self.analytics_page_url(**opt)
    opt.except!(:module, :action)
    seg = opt.delete(:segment)
    prm = opt.delete(:parameters) || {}
    cat = opt.delete(:category)
    sub = opt.delete(:subcategory) || prm[:idGoal] || 'General_Overview'
    url = analytics_url(**opt)
    opt[:category]    = LIVE_CATEGORY[cat]    || cat  if cat
    opt[:subcategory] = LIVE_SUBCATEGORY[sub] || sub  if sub
    opt[:segment]     = seg                           if seg
    url << '#?' << url_query(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Matomo JavaScript asset.
  #
  # This should be included at the end of `<head>`.
  #
  # @param [User, String, Integer, nil] for_user
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def self.script_element(for_user = nil)
    user    = User.instance_for(for_user)
    user_id = user&.email
    visitor = ('%016d' % user.id if user)
    <<~HEREDOC.squish.html_safe
      <script type="text/javascript" data-cid="#{visitor}">
        let _paq = window._paq = window._paq || [];
        #{"_paq.push(['setUserId',    '#{user_id}']);" if user_id}
        #{"_paq.push(['setVisitorId', '#{visitor}']);" if visitor}
        _paq.push(['trackPageView']);
        _paq.push(['enableLinkTracking']);
        (function() {
          _paq.push(['setTrackerUrl', '#{tracker_url}']);
          _paq.push(['setSiteId', '#{site}']);
          const g = document.createElement('script');
          const s = document.getElementsByTagName('script')[0];
          g.async = true;
          g.src   = '#{script_url}';
          s.parentNode.insertBefore(g, s);
        })();
      </script>
    HEREDOC
  end

  # Element inserted to cause a page to be counted if JavaScript is disabled.
  #
  # @param [Hash] opt                 Passed to Matomo#image.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def self.no_js(**opt)
    opt[:src] = make_path(tracker_url, idSite: site, rec: 1)
    image(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get analytics summary information.
  #
  # @param [Hash] opt
  #
  # @return [Hash{String=>any}]
  #
  def self.info(**opt)
    api_request(method: :get, **opt)
  end

  # Get analytics report graphs.
  #
  # @param [Symbol, nil] target       Target output format; default: :html.
  # @param [Hash]        opt
  #
  # @return [Hash{String=>any}]
  #
  def self.reports(target: nil, **opt)
    api_request(method: :getReportMetadata , **opt) do |result|
      process_report_result(result, target: target)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Perform a Matomo request.
  #
  # @param [Hash] opt                 Passed to #api_request_url.
  #
  # @return [Hash{String=>any}]
  #
  def self.api_request(**opt)
    url  = api_request_url(**opt)
    resp = Faraday.get(url)
    stat = resp&.status || '-'
    body = resp&.body&.strip
    safe_json_parse(body, default: nil).then { |result|
      if result && block_given?
        yield(result)
      elsif result.is_a?(Hash)
        result.sort_by { _1.to_s.downcase }.to_h
      elsif result.is_a?(Array)
        result.flat_map.with_index(1) { |value, i|
          case value
            when Hash then value.map { |k, v| ["#{i} #{k}", v] }
            when nil  then [[i, nil]]
            else           [[i, value.inspect]]
          end
        }.to_h
      else
        error = (stat == 200) ? 'no content' : "status #{stat}"
        error = "#{__method__}: failed: #{url.inspect} (#{error})"
        Log.error(error)
        { error: error }
      end
    }.stringify_keys.transform_values { _1.nil? ? EMPTY_VALUE : _1 }
  rescue => error
    Log.warn { "Matomo.#{__method__}: #{error.class}: #{error.message}" }
    re_raise_if_internal_exception(error)
    {}
  end

  # Build a Matomo request URL.
  #
  # @param [Hash] opt                 Passed to #api_request_parameters.
  #
  # @return [String]
  #
  def self.api_request_url(**opt)
    opt = api_request_parameters(**opt) unless opt[:token_auth].present?
    analytics_path(**opt)
  end

  # Normalize Matomo request URL parameters.
  #
  # @param [Hash] opt
  #
  # @option opt [Symbol] :format      Response format; default: :json.
  #
  # @return [Hash]
  #
  # @see https://developer.matomo.org/api-reference/reporting-api#standard-api-parameters
  # @see https://developer.matomo.org/api-reference/reporting-api#api-method-list
  #
  def self.api_request_parameters(**opt)
    opt[:format] ||= :json
    module_method!(opt)
    id_site!(opt)
    token_auth!(opt)
    date_period!(opt)
    from_bool!(opt, :flat, :flatten)
    from_bool!(opt, :expanded, :expand)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Map :date parameter values to their implied :period parameter values.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  DATE_PERIOD = {
    today:      :day,
    yesterday:  :day,
    lastWeek:   :week,
    lastMonth:  :month,
    lastYear:   :year,
  }.freeze

  # Map :period parameter values to their implied :date parameter values.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  PERIOD_DATE = {
    day:        :yesterday,
    week:       :lastWeek,
    month:      :lastMonth,
    year:       :lastYear,
  }.freeze

  # Set :date and :period URL parameters.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def self.date_period!(opt)
    date, period = opt.values_at(:date, :period)
    date = "#{date.first},#{date.last}" if date.is_a?(Array)
    # noinspection RubyParenthesesAroundConditionInspection
    if period
      date ||= PERIOD_DATE[period.to_sym]
    elsif date.is_a?(Symbol)
      period = DATE_PERIOD[date]
    elsif date.is_a?(String) && date.include?(',')
      period = :range
    elsif (date.to_date rescue nil)
      period = :day
    elsif date.is_a?(String)
      period = DATE_PERIOD[date.to_sym]
    else
      finish = Date.today
      start  = finish - DEFAULT_RANGE
      date   = [start, finish].join(',')
      period = :range
    end
    opt[:date]   = date   || :today
    opt[:period] = period || :day
    opt
  end

  # Set :module and :method URL parameters.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def self.module_method!(opt)
    opt[:module] = mod  = opt[:module]&.to_s || 'API'
    opt[:method] = meth = opt[:method]&.to_s || '[missing]'
    opt[:method] = "#{mod}.#{meth}" unless meth.start_with?(mod)
    opt
  end

  # Set :idSite URL parameter.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def self.id_site!(opt)
    opt[:idSite] = opt.key?(:site) && opt.delete(:site) || site
    opt
  end

  # Set :token_auth URL parameter.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def self.token_auth!(opt)
    opt[:token_auth] = opt.delete(:auth_token) || opt[:token_auth] || TOKEN
    opt
  end

  # Set :token_auth URL parameter.
  #
  # @param [Hash]          opt
  # @param [Symbol]        key
  # @param [Array<Symbol>] alt_keys   Aliases that should not be passed to URL
  #
  # @return [Hash]
  #
  def self.from_bool!(opt, key, *alt_keys)
    alt_val  = opt.extract!(*alt_keys).first
    opt[key] = alt_val          if alt_val.present?
    opt[key] = opt[key] ? 1 : 0 if opt[key].is_a?(BoolType)
    opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Allow/reject report by :module.
  #
  # @type [Hash{Symbol=>Boolean}]
  #
  REPORT_BY_MODULE = {
    API:              false,
    Actions:          true,
    Contents:         false,
    DevicePlugins:    false,
    DevicesDetection: true,
    Events:           false,
    Goals:            true,
    MultiSites:       false,
    PagePerformance:  true,
    Referrers:        true,
    Resolution:       true,
    UserCountry:      true,
    UserId:           true,
    UserLanguage:     true,
    VisitFrequency:   true,
    VisitTime:        true,
    VisitorInterest:  true,
    VisitsSummary:    true,
  }.freeze

  # Allow/reject report by :action.
  #
  # Actions like :get and :getAll that are common to several modules must be
  # *true* here and filtered by module.
  #
  # @type [Hash{Symbol=>Boolean}]
  #
  REPORT_BY_ACTION = {
    get:                                true,   # NOTE: must filter by module
    getAction:                          false,
    getAll:                             true,   # NOTE: must filter by module
    getBrand:                           true,
    getBrowserEngines:                  true,
    getBrowserVersions:                 true,
    getBrowsers:                        true,
    getByDayOfWeek:                     true,
    getCampaigns:                       false,
    getCategory:                        false,
    getCity:                            false,
    getConfiguration:                   false,
    getContentNames:                    false,
    getContentPieces:                   false,
    getContinent:                       false,
    getCountry:                         true,
    getDaysToConversion:                false,
    getDownloads:                       true,
    getEntryPageTitles:                 true,
    getEntryPageUrls:                   true,
    getExitPageTitles:                  false,
    getExitPageUrls:                    false,
    getKeywords:                        false,
    getLanguage:                        false,
    getLanguageCode:                    true,
    getModel:                           true,
    getName:                            false,
    getNumberOfVisitsByDaysSinceLast:   true,
    getNumberOfVisitsByVisitCount:      true,
    getNumberOfVisitsPerPage:           true,
    getNumberOfVisitsPerVisitDuration:  true,
    getOne:                             false,
    getOsFamilies:                      true,
    getOsVersions:                      true,
    getOutlinks:                        true,
    getPageTitles:                      true,
    getPageTitlesFollowingSiteSearch:   false,
    getPageUrls:                        true,
    getPageUrlsFollowingSiteSearch:     false,
    getPlugin:                          false,
    getReferrerType:                    true,
    getRegion:                          false,
    getResolution:                      true,
    getSearchEngines:                   true,
    getSiteSearchCategories:            false,
    getSiteSearchKeywords:              false,
    getSiteSearchNoResultKeywords:      false,
    getSocials:                         false,
    getType:                            true,
    getUsers:                           true,
    getVisitInformationPerLocalTime:    true,
    getVisitInformationPerServerTime:   true,
    getVisitsUntilConversion:           false,
    getWebsites:                        false,
  }.freeze

  # Modules which should not display a second entry (evolution graph).
  #
  # @type [Array<Symbol>]
  #
  NO_EVOLUTION = %i[Goals PagePerformance VisitFrequency VisitsSummary].freeze

  # Modules which should not display a second entry (evolution graph) for the
  # 'get' action.
  #
  # @type [Array<Symbol>]
  #
  NO_GET_EVOLUTION = %i[Actions Referrers].freeze

  # Create a table of graph images from an analytics report.
  #
  # @param [Array<Hash>, Hash, nil] values
  # @param [Symbol, nil]            target
  #
  # @return [Hash]
  #
  def self.process_report_result(values, target: nil, **)
    html_out = target.nil? || (target == :html)
    Array.wrap(values).flat_map { |value|
      next unless REPORT_BY_MODULE[(m = value[:module]&.to_sym)]
      next unless REPORT_BY_ACTION[(a = value[:action]&.to_sym)]

      # Skip bogus goal report.
      next if (a == :get) && value.dig(:parameters, :idGoal)&.to_i&.zero?

      # Edit certain report names for clarity.
      changed =
        case (name = value[:name])
          when 'Goals'   then name = "#{name}: All Search Types"
          when /^(Goal)/ then name = name.sub($1, "#{$1}:")
        end
      value  = value.merge(name: name) if changed

      # One entry pair for the basic summary graph.
      graph1 = value[:imageGraphUrl]
      graph1 = analytics_path(graph1)                if graph1
      graph1 = image(src: graph1, decoding: 'async') if graph1 && html_out

      # A second entry pair for the evolution graph (which is not provided for
      # some reports).
      graph2 = value[:imageGraphEvolutionUrl]
      graph2 = nil if NO_EVOLUTION.include?(m)
      graph2 = nil if (a == :get) && NO_GET_EVOLUTION.include?(m)
      graph2 = analytics_path(graph2)                if graph2
      graph2 = image(src: graph2, decoding: 'async') if graph2 && html_out

      # Produce one or two entries for the report.
      if graph1 && graph2
        lbl1 = report_label(value, note: 'totals') # TODO: I18n
        lbl2 = report_label(value.slice(:name), note: 'over time') # TODO: I18n
        [[lbl1, graph1], [lbl2, graph2]]
      else
        lbl1 = report_label(value)
        [[lbl1, (graph1 || graph2)]]
      end
    }.compact.to_h
  end

  # Construct a `<dt>` name from a report value.
  #
  # @param [Hash{Symbol=>any}] value
  # @param [String, nil]       note   Appended to name if present
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def self.report_label(value, note: nil, **)
    parts = []
    if (name = value[:name]).present?
      name = element(:span, name, class: 'base')
      name << ' ' << element(:span, "(#{note})", class: 'note') if note
      parts << element(:h3, name, class: 'action-name')
    end
    if (doc = value[:documentation]).present?
      lines = doc.split(%r{<br */>}).map! { element(:p, _1) }
      lines = lines.join("\n").html_safe
      parts << element(:div, lines, class: 'action-description')
    end
    if (guide = value[:onlineGuideUrl]).present?
      guide = out_link(guide)
      guide = "(More info at #{guide})".html_safe # TODO: I18n
      parts << element(:p, guide, class: 'action-guide')
    end
    if (link = value.slice(:category, :subcategory, :parameters)).present?
      url  = analytics_page_url(**link)
      site = out_link(url, 'interactive site', class: 'button') # TODO: I18n
      site = "See this on the #{site}.".html_safe # TODO: I18n
      parts << element(:p, site, class: 'action-site-link')
    end
    parts.join("\n").html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate an HTML `<img>` element.
  #
  # @param [String] src
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def self.image(src:, **opt)
    opt[:src]              = src
    opt[:alt]            ||= ''
    opt[:style]          ||= 'border:0'
    opt[:referrerpolicy] ||= 'no-referrer-when-downgrade'
    element(:img, **opt)
  end

  # Generate an HTML `<a>` active link to external site.
  #
  # @param [String]      url
  # @param [String, nil] label        Default: *url*.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def self.out_link(url, label = nil, **opt)
    label ||= ERB::Util.h(url.delete_suffix('/'))
    element(:a, label, href: url, target: '_blank', **opt)
  end

  # Generate an HTML element.
  #
  # @param [Symbol, String]                         tag
  # @param [ActiveSupport::SafeBuffer, String, nil] content
  # @param [Hash]                                   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def self.element(tag, content = nil, **opt)
    tag_close = tag
    if opt.present?
      attr = opt.map { "#{_1}='#{ERB::Util.h(_2)}'" }.join(' ')
      tag  = "#{tag} #{attr}"
    end
    if content
      content = sanitize(content) unless content.html_safe?
      "<#{tag}>#{content}</#{tag_close}>".html_safe
    else
      "<#{tag} />".html_safe
    end
  end

  # Replace most HTML elements with the text they enclose.
  #
  # @param [String, nil] text
  #
  # @return [String]
  #
  def self.sanitize(text)
    text = text.to_s.gsub(/<title>/) { ERB::Util.h(_1) }
    Sanitize.fragment(text, **Sanitize::Config::RESTRICTED)
  end

end

__loading_end(__FILE__)
