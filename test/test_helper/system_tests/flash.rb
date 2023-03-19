# test/test_helper/system_tests/flash.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for checking flash messages.
#
module TestHelper::SystemTests::Flash

  include TestHelper::SystemTests::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether a flash message is present.  If neither :alert nor :notice
  # is specified then any element with *text* under '.flash-messages' will
  # match.
  #
  # If no text is given, the presence of any flash message is indicated.
  #
  # @param [String, nil]    content   Expect a flash of any kind with this.
  # @param [String]         alert     Expect a flash alert with this.
  # @param [String]         notice    Expect a flash notice with this.
  # @param [String]         text      Expect a flash of any kind with this.
  # @param [String,Boolean] without   Negate expectation.
  # @param [Boolean]        assert    If not *true*, return Boolean.
  # @param [Hash]           opt       Passed to Capybara method.
  #
  def flash?(
    content = nil,
    alert:    nil,
    notice:   nil,
    text:     nil,
    without:  false,
    assert:   false,
    **opt
  )
    terms = [content, alert, notice, text].compact
    # noinspection RubyMismatchedArgumentType
    if without.is_a?(String)
      terms << without
      text ||= without
    end
    raise 'Too many expected terms' if terms.many?
    type = '*'
    type = '.alert'  if text.nil? && (text = alert)
    type = '.notice' if text.nil? && (text = notice)
    opt[:text] = text if (text ||= content)
    if assert
      meth = without ? :assert_no_selector : :assert_selector
    else
      meth = without ? :has_no_selector?   : :has_selector?
    end
    send(meth, ".flash-messages #{type}", **opt)
  end

  # Indicate that a flash message not is present.
  #
  # @param [String, nil] content      Passed to #flash?.
  # @param [Hash]        opt          Passed to #flash?.
  #
  def no_flash?(content = nil, **opt)
    opt.reverse_merge!(without: true)
    flash?(content, **opt)
  end

  # Assert that a flash message is present.
  #
  # @param [String, nil] content      Passed to #flash?.
  # @param [Hash]        opt          Passed to #flash?.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def assert_flash(content = nil, **opt)
    opt.reverse_merge!(assert: true)
    flash?(content, **opt)
  end

  # Assert that a flash message is not present.
  #
  # @param [String, nil] content      Passed to #flash?.
  # @param [Hash]        opt          Passed to #flash?.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def assert_no_flash(content = nil, **opt)
    opt.reverse_merge!(assert: true)
    no_flash?(content, **opt)
  end

end
