# test/test_helper/system_tests/cookies.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for accessing response cookies.
#
module TestHelper::SystemTests::Cookies

  include TestHelper::SystemTests::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Shortcut to the browser client interface.
  #
  def browser
    @browser ||= Capybara.current_session.driver.browser
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Display the current cookies from the last response.
  #
  # @return [void]
  #
  # @note Currently unused
  #
  def show_cookies
    show_item('COOKIES:') do
      get_cookies.map do |k, v|
        value = v[:value] || ''
        "#{k.inspect} = #{v.inspect} [#{value.size} bytes]"
      end
    end
  end

  # Get the current cookies from the last response.
  #
  # @return [Hash]
  #
  def get_cookies
    if browser.respond_to?(:cookie_jar) # Rack::Test::Session
      browser.cookie_jar.to_hash
    elsif browser.respond_to?(:manage) # Selenium::WebDriver
      browser.manage.all_cookies.map { [_1[:name], _1] }.to_h
    else
      raise "#{__method__}: failed for browser #{browser.inspect}"
    end
  end

  # Clear all browser cookies.
  #
  # @note Use of this may not be compatible with the way that EMMA sets up
  #   single-click authentication for tests.
  #
  # @return [void]
  #
  def clear_cookies
    if browser.respond_to?(:clear_cookies) # Rack::Test::Session
      browser.clear_cookies
    elsif browser.respond_to?(:manage) # Selenium::WebDriver
      browser.manage.delete_all_cookies
    else
      raise "#{__method__}: failed for browser #{browser.inspect}"
    end
  end

end
