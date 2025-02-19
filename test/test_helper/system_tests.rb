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
    include Capybara::Node::Actions                 # for :click_on alias
    include TestHelper::SystemTests::Authentication # disambiguate :sign_in_as
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the submodules defined in test/test_helper/system_tests/*.
  #
  # @param [Module] base
  #
  def self.included(base)
    include_submodules(base, __FILE__)
    base.extend(TestHelper::Common)
  end

end
