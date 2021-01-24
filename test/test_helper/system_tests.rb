# test/test_helper/system_tests.rb
#
# frozen_string_literal: true
# warn_indent:           true

# System test support methods.
#
module TestHelper::SystemTests

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    # Alias for Capybara::Node::Actions#click_link_or_button isn't being seen
    # by dynamic checking for some reason.
    def click_on(locator = nil, **opt); click_link_or_button(locator, opt); end
  end
  # :nocov:

  # Include the submodules defined in test/test_helper/system_tests/*.
  #
  # @param [Module] base
  #
  # @private
  #
  def self.included(base)
    include_submodules(base, __FILE__) do |name|
      next if (name == :Bookshare) && !TESTING_BOOKSHARE_API
    end
  end

end
