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
  # @param [String,nil] text          If given both must match.
  # @param [String,nil] heading       Default: *text* if given.
  # @param [String,nil] title         Default: *text* if given.
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the given URL without its HTTP port.
  #
  # @param [String, nil]  url
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

  # Block until the browser can confirm that it is on the target page.
  #
  # @param [String]  target_url
  # @param [Integer] wait             Overall time limit.
  # @param [Integer] max              Maximum number of attempts to make.
  # @param [Boolean] port             Passed to #get_browser_url.
  #
  # @return [Boolean]
  #
  def wait_for_page(target_url, wait: nil, max: 5, port: false)
    wait ||= 2 * Capybara.default_max_wait_time
    timer = Capybara::Helpers::Timer.new(wait)
    max.times do
      return true if get_browser_url(port: port) == target_url
      break if timer.expired?
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
    take_screenshot
  rescue Selenium::WebDriver::Error::UnknownError => error
    $stderr.puts "*** CAUGHT #{error.class} - #{error.message}"
  end
    .tap { |meth| neutralize(meth) unless DEBUG_TESTS }

end
