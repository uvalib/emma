# test/test_helper/system_tests.rb
#
# frozen_string_literal: true
# warn_indent:           true

# System test support methods.
#
module TestHelper::SystemTests

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Capybara::Node::Actions                 # for :click_on alias
    include TestHelper::SystemTests::Authentication # disambiguate :sign_in_as
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the submodules defined in test/test_helper/system_tests/*.
  #
  # @param [Module] base
  #
  def self.included(base)
    include_submodules(base, __FILE__) do |name|
      (name != :Bookshare) || TEST_BOOKSHARE.present?
    end
    base.extend(TestHelper::Common)
  end

end
