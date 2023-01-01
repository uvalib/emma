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
    include Capybara::Node::Finders                 # for :click_on alias
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
    assert_equal url, URI(current_url).tap { |uri| uri.port = nil }.to_s
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
  def assert_json(value = nil, exact: nil, **pairs)
    # noinspection RubyNilAnalysis
    if value.nil?
      value = pairs
    elsif value.is_a?(String) || value.is_a?(Array)
      value = json_parse(value, symbolize_keys: false) || {}
    elsif exact.nil? && value.key?(:exact)
      exact = value[:exact]
      value = value.except(:exact)
    end
    text = value.to_json
    text = text[1...-1] unless exact
    assert false if text.blank?
    assert text, exact: !!exact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the given URL without its HTTP port.
  #
  # @param [String, nil] url
  #
  # @return [String, nil]
  #
  def url_without_port(url)
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

  DEFAULT_WAIT_MAX_TIME = 3 * Capybara.default_max_wait_time
  DEFAULT_WAIT_MAX_PASS = 5

  # Block until the browser can confirm that it is on the target page.
  #
  # @param [String, Array] target     One or more acceptable target URLs.
  # @param [Integer]       wait       Overall time limit.
  # @param [Integer]       max        Maximum number of attempts to make.
  # @param [Boolean]       port       Passed to #get_browser_url.
  # @param [Boolean]       assert     If *false* don't assert.
  # @param [Boolean]       trace      Output each URL acquired.
  #
  # @raise [Minitest::Assertion]      If the browser failed to get to the page.
  #
  # @return [Boolean]
  #
  def wait_for_page(
    target,
    wait:   DEFAULT_WAIT_MAX_TIME,
    max:    DEFAULT_WAIT_MAX_PASS,
    port:   false,
    assert: true,
    trace:  true
  )
    timer   = Capybara::Helpers::Timer.new(wait)
    current = nil
    targets = Array.wrap(target)
    max.times do
      current = get_browser_url(port: port)
      show("#{__method__}: URL = #{current}") if trace
      success_screenshot if trace
      return true if targets.include?(current)
      break       if timer.expired?
    end
    if assert
      current  = url_without_port(current || current_url).inspect
      expected = targets.many? ? targets.map(&:inspect) : targets.pop.inspect
      if expected.is_a?(Array)
        # noinspection RubyNilAnalysis, RubyMismatchedArgumentType
        expected = [] << expected[0...-1].join(', ') << 'or' << expected.last
        expected = 'any of expected pages %s' % expected.join(' ')
      else
        expected = "expected page #{expected}"
      end
      flunk "Browser on page #{current} and not on #{expected}"
    end
    false
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
  def success_screenshot
    take_screenshot if TESTING_JAVASCRIPT
  rescue Selenium::WebDriver::Error::UnknownError => error
    $stderr.puts "[Screenshot Image]: #{error.class} - #{error.message}"
  end
    .tap { |meth| neutralize(meth) unless DEBUG_TESTS }

end
