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

  # Assert that a flash message is present.  If neither :alert nor :notice is
  # specified then any element with *text* under '.flash-messages' will match.
  #
  # @param [String, nil] text
  # @param [Hash]        opt
  #
  # @option opt [String] :alert       Flash alert text
  # @option opt [String] :notice      Flash notice text.
  #
  def assert_flash(text = nil, **opt)
    selector = %w(.flash-messages)
    if opt[:notice]
      selector << '.notice'
      text = opt[:notice]
    elsif opt[:alert]
      selector << '.alert'
      text = opt[:alert]
    else
      selector << '*'
    end
    assert_selector selector.join(' '), text: text
  end

end
