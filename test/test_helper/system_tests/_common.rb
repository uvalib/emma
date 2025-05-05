# test/test_helper/system_tests/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Common values for system tests.
#
# @!method visit
#   @param [#to_s] visit_uri
#   @see Capybara::Session#visit
#
# @!method go_back
#   @see Capybara::Session#go_back
#
module TestHelper::SystemTests::Common

  include TestHelper::Common
  include Emma::Json

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Minitest::Assertions                    # for #flunk
    include Capybara::Node::Actions                 # for #select
    include Capybara::Node::Finders                 # for #find
    include ActionDispatch::Routing::UrlFor         # for #url_for
    include TestHelper::SystemTests::Authentication # disambiguate :sign_in_as
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the number of total records reported by a counter element.
  #
  # @param [Integer, nil] expected    Assert that the expected count is found.
  # @param [String, nil]  selector    Additional counter element selector.
  # @param [String]       css         Base counter element selector.
  #
  # @return [Integer]
  #
  def title_total_count(expected: nil, selector: nil, css: '.total-count')
    css   = [selector, css].compact.map { '.%s' % _1.delete_prefix('.') }.join
    total = find(css, match: :first).text.to_i
    unless expected.nil? || (total == expected)
      flunk "count is #{total} instead of #{expected}"
    end
    total
  end

  # Get the number of total records from the 'data-record-total' attribute of a
  # table element.
  #
  # @param [Integer, nil] expected    Assert that the expected count is found.
  # @param [String, nil]  selector    Additional table selector.
  # @param [String]       css         Base table selector.
  #
  # @return [Integer]
  #
  def data_record_total(expected: nil, selector: nil, css: '.model-table')
    css   = [selector, css].compact.map { '.%s' % _1.delete_prefix('.') }.join
    total = find(css, match: :first)[:'data-record-total'].to_i
    unless expected.nil? || (total == expected)
      flunk "count is #{total} instead of #{expected}"
    end
    total
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that *url* matches `current_url`.
  #
  # @param [String] url
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def assert_current_url(url)
    cur = URI.parse(current_url)
    (s  = cur.scheme) and (s = "#{s}:")
    (h  = cur.host)   and (h = "//#{h}")
    url =
      case url
        when %r{^([^:/]+://[^:/]+)(:\d+)?(/.*)} then [$1, $3].join
        when %r{^(//[^:/]+)(:\d+)?(/.*)}        then [s, $1, $3].join
        else                                         make_path("#{s}#{h}", url)
      end
    assert_equal url, url_without_port(cur)
  end

  # Assert that the current page is valid.
  #
  # @param [String, nil] text         If given both must match.
  # @param [String, nil] heading      Default: *text* if given.
  # @param [String, nil] title        Default: *text* if given.
  #
  # @raise [Minitest::Assertion]      If either item is not on the page.
  #
  # @return [true]
  #
  def assert_valid_page(text = nil, heading: nil, title: nil, **)
    assert_selector 'h1', text: heading if (heading ||= text)
    assert_title title                  if (title   ||= text)
    assert_no_flash('service error')
  end

  # Assert that the current output is JSON with the given key/value pairs.
  #
  # @note The pairs must be in the expected order.
  #
  # @param [Hash, String, nil] value  Key/value pairs or (partial) JSON.
  # @param [Boolean, nil]      exact
  # @param [Hash]              pairs  Key/value pairs if value is nil.
  #
  # @raise [Minitest::Assertion]      If *pairs* are not present or incomplete.
  #
  # @return [true]
  #
  # @note Currently unused.
  # :nocov:
  def assert_json(value = nil, exact: nil, **pairs)
    if value.nil?
      value = pairs
    elsif value.is_a?(String)
      value = json_parse(value, symbolize_keys: false) || {}
    elsif value.is_a?(Hash) && exact.nil? && value.key?(:exact)
      value = value.dup
      exact = value.delete(:exact)
    end
    text = value.to_json
    text = text[1...-1] unless exact
    assert text.present?
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the given URL without its HTTP port.
  #
  # @param [String, URI::Generic, nil] url
  #
  # @return [String, nil]
  #
  def url_without_port(url)
    URI(url).tap { _1.port = nil }.to_s if url
  end

  # Block until the browser can report its 'window.location'.
  #
  # @param [Boolean] port             If *true*, allow port in URL comparison.
  #
  # @return [String, nil]
  #
  def get_browser_url(port: false)
    url = nil
    page.document.synchronize do
      url = evaluate_script('window.location.href').presence
    end
    (url && !port) ? url_without_port(url) : url
  end

  DEF_WAIT_MAX_PASS = 5
  DEF_WAIT_MAX_TIME = Capybara::Lockstep.timeout * DEF_WAIT_MAX_PASS * 2

  # Block until the supplied condition is met.
  #
  # @param [Boolean] fatal            If *true*, then assert.
  # @param [Numeric] wait             Overall time limit.
  #
  # @raise [Minitest::Assertion]      If failed and *fatal* is *true*.
  #
  # @return [Boolean]
  #
  def wait_for_condition(fatal: false, wait: DEF_WAIT_MAX_TIME)
    pass    = -1
    timer   = Capybara::Helpers::Timer.new(wait)
    timeout = nil

    # Retry until the condition is met or the timer expires.
    until (found = yield(pass += 1))
      break if (timeout = timer.expired?)
      show_item { "[waiting] pass #{pass}" }
      screenshot
      sleep Capybara::Lockstep.timeout
    end

    # Done waiting and now either *found* or *timeout* is true.
    show_item { "[timeout] pass #{pass}" } if timeout && !fatal
    screenshot
    flunk "[timeout] pass #{pass}"         if timeout && fatal

    !!found
  end

  # Block until the browser can confirm that it is on the target page.
  #
  # @param [Array, nil] targets       One or more acceptable target URLs, or
  #                                     *nil* for any new page.
  # @param [Boolean]    port          Passed to #get_browser_url.
  # @param [Boolean]    fatal         If *false*, don't assert.
  # @param [Boolean]    trace         Output each URL acquired.
  # @param [Numeric]    wait          Overall time limit.
  #
  # @raise [Minitest::Assertion]      If the browser failed to get to the
  #                                     expected page and *fatal* is *true*.
  #
  # @return [Boolean]
  #
  def wait_for_page(
    *targets,
    port:   false,
    fatal:  true,
    trace:  true,
    wait:   DEF_WAIT_MAX_TIME
  )
    targets = targets.flatten.compact_blank.presence
    timer   = Capybara::Helpers::Timer.new(wait)
    timeout = found = url = nil

    # Retry until the expected page is found or the timer expires.
    loop do
      url = get_browser_url(port: port)
      break if (found   = targets ? targets.include?(url) : url.present?)
      break if (timeout = timer.expired?)
      show_url(url, '[waiting]') if trace
      sleep Capybara::Lockstep.timeout
    end

    # Done waiting and now either *found* or *timeout* is true.
    show_url(url, ('[timeout]' if timeout)) if trace
    screenshot
    if timeout && fatal
      current    = url_without_port(url || current_url).inspect
      page       = targets&.map!(&:inspect)&.pop
      expected   = targets&.presence&.join(', ')
      expected &&= "any of expected pages #{expected} or #{page}"
      expected ||= page ? "expected page #{page}" : 'a new page'
      flunk "Browser on page #{current} and not on #{expected}"
    end

    found
  end

  # Depending on the context, there may be two menus for performing an action
  # on a selected item.
  #
  # In cases where there are dual select menus (one for the user's own items
  # and one for organization items) the first menu will contain a subset of the
  # items from the second menu.
  #
  # @param [String] value
  # @param [String] name
  # @param [Hash]   opt               Passed to Capybara::Node::Actions#select
  #
  # @return [void]
  #
  # @see BaseDecorator::Menu#items_menu
  #
  def item_menu_select(value, name:, **opt)
    selector = %Q{select[name="#{name}"]:not([data-secondary])}
    menu_select(value, from: selector, **opt)
  end

  # Select a menu item either from a simple HTML `<select>` menu or one that
  # is managed by Select2.
  #
  # @param [String] value
  # @param [String] from
  # @param [Hash]   opt               Passed to Capybara::Node::Finders#find
  #
  # @return [void]
  #
  def menu_select(value, from:, **opt)
    opt[:exact_text] = true unless opt.key?(:exact_text)
    case from
      when /^select/ then selector = from
      when /^\[/     then selector = "select#{from}"
      else                selector = "select##{from}"
    end
    menu = find(selector, **opt)
    if menu[:class]&.split(' ')&.include?('select2-hidden-accessible')
      select2(value, css: "#{selector} + .select2-container", **opt)
    else
      menu.select(value, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the variant of the action which indicates generation of a menu.
  #
  # @param [Symbol, String] action
  #
  # @return [Symbol]
  #
  def menu_action(action)
    ParamsHelper.menu_action(action)
  end

  # Return the expected URL(s) for an action form page.
  #
  # @param [Integer, String, nil] id
  # @param [Hash]                 params
  #
  # @return [Array<String>]           If *id* is given.
  # @return [String]                  If *id* is not given.
  #
  def form_page_url(id = nil, **params)
    if id
      [url_for(**params, id: id), make_path(url_for(**params), id: id)]
    else
      url_for(**params)
    end
  end

  # Assert that the requested URL could not be visited and that an appropriate
  # flash error message was displayed.
  #
  # @param [String, Array<String>]     url
  # @param [String, Symbol, nil]       action Basis for expected flash message.
  # @param [String, Symbol, User, nil] as     Sign-in as user.
  #
  # @return [void]
  #
  def assert_no_visit(url, action = nil, as: nil)
    sign_in_as(as)  if as
    url = url.first if url.is_a?(Array)
    visit url
    screenshot
    assert_no_current_path(url)
    assert_not_authorized(action) if action
  end

  # Assert that an appropriate flash error message is being displayed.
  #
  # @param [String, Symbol, nil] action
  #
  # @return [void]
  #
  def assert_not_authorized(action)
    action = not_authorized_for(action) if action.is_a?(Symbol)
    assert_flash(action) if action.is_a?(String)
  end

  # Text indicating an administrator feature.
  #
  # @type [String]
  #
  ADMIN_ONLY = I18n.t('emma.term.user.privileged', Role:'Administrator').freeze

  # Text indicating an authentication failure.
  #
  # @type [String]
  #
  AUTH_FAILURE = I18n.t('devise.failure.unauthenticated').freeze

  # Return a partial flash message based on *action*.
  #
  # @param [Symbol, String, nil] action
  #
  # @return [String]
  #
  def not_authorized_for(action)
    case action&.to_sym
      when :admin_only  then ADMIN_ONLY
      when :sign_in     then AUTH_FAILURE
      when nil          then 'You are not authorized'
      when :index       then 'You are not authorized to list'
      when :show        then 'You are not authorized to view'
      when :new         then 'You are not authorized to create'
      when :edit        then 'You are not authorized to modify'
      when :delete      then 'You are not authorized to remove'
      else                   "You are not authorized to #{action}"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If DEBUG_TESTS is true, this will take a screenshot (ignoring an error that
  # has been observed [in rare cases] since these are informational-only).
  #
  # @param [Hash] opt                 Passed to #take_screenshot.
  #
  # @return [void]
  #
  def screenshot(**opt)
    take_screenshot(**opt)
  rescue Selenium::WebDriver::Error::UnknownError => error
    show_item { "[Screenshot Image]: #{error.class} - #{error.message}" }
  end
    .tap { neutralize(_1) unless DEBUG_TESTS && TESTING_JAVASCRIPT }

end
