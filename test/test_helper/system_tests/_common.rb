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
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Minitest::Assertions                    # for #flunk
    include Capybara::Node::Actions                 # for #select
    include Capybara::Node::Finders                 # for #find
    include TestHelper::SystemTests::Authentication # disambiguate :sign_in_as
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # assert_current_url
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
        else                                         File.join("#{s}#{h}", url)
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
    assert_no_flash 'service error'
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
  # @note Currently unused
  #
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
    # noinspection RubyMismatchedArgumentType
    URI(url).tap { |uri| uri.port = nil }.to_s if url
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

  # Block until the browser can confirm that it is on the target page.
  #
  # @param [String, Array, nil] target  One or more acceptable target URLs, or
  #                                       *nil* for any new page.
  # @param [Boolean]            port    Passed to #get_browser_url.
  # @param [Boolean]            fatal   If *false* don't assert.
  # @param [Boolean]            trace   Output each URL acquired.
  # @param [Numeric]            wait    Overall time limit.
  #
  # @raise [Minitest::Assertion]        If the browser failed to get to the
  #                                       expected page and *fatal* is *true*.
  #
  # @return [Boolean]
  #
  def wait_for_page(
    target =  nil,
    port:     false,
    fatal:    true,
    trace:    true,
    wait:     DEF_WAIT_MAX_TIME
  )
    targets = Array.wrap(target).compact_blank
    timer   = Capybara::Helpers::Timer.new(wait)
    url     = nil

    # Retry until the expected page is found or the timer expires.
    loop do
      url     = get_browser_url(port: port)
      found   = url && (targets.empty? || targets.include?(url))
      timeout = (' [timeout]' if !found && timer.expired?)
      show "#{__method__}: URL = #{url}#{timeout}" if trace
      screenshot   if found || timeout
      return true  if found
      return false if timeout && !fatal
      break        if timeout
      sleep Capybara::Lockstep.timeout
    end

    # Control reaches here only if the page was not found and not *fatal*.
    # noinspection RubyMismatchedArgumentType
    current = url_without_port(url || current_url).inspect
    target  = targets.map!(&:inspect).pop
    if targets.present?
      expected = "any of expected pages %s or #{target}" % targets.join(', ')
    elsif target.present?
      expected = "expected page #{target}"
    else
      expected = 'a new page'
    end
    flunk "Browser on page #{current} and not on #{expected}"
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
  # @return [Capybara::Node::Element]
  #
  def item_menu_select(value, name:, **opt)
    menu = all(%Q(select[name="#{name}")).last
    # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
    select value, from: menu[:id], **opt
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If DEBUG_TESTS is true, this will take a screenshot (ignoring an error that
  # has been observed [in rare cases] since these are informational-only).
  #
  # @return [void]
  #
  def screenshot
    take_screenshot
  rescue Selenium::WebDriver::Error::UnknownError => error
    show_item("[Screenshot Image]: #{error.class} - #{error.message}")
  end
    .tap { |meth| neutralize(meth) unless DEBUG_TESTS && TESTING_JAVASCRIPT }

end
