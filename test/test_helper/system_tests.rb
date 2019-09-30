# test/test_helper/system_tests.rb
#
# frozen_string_literal: true
# warn_indent:           true

# System test support methods.
#
module TestHelper::SystemTests

  # Include the submodules defined in test/test_helper/system_tests/*.
  #
  # @param [Module] base
  #
  # @return [Array<Module>]           @see #include_submodules
  #
  def self.included(base)
    include_submodules(base, __FILE__) do |name|
      next if (name == :Bookshare) && !TESTING_BOOKSHARE_API
    end
  end

end
