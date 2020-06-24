# test/test_helper/integration_tests.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Extensions for controller and system tests.
#
module TestHelper::IntegrationTests

  # Include the submodules defined in test/test_helper/integration_tests/*.
  #
  # @param [Module] base
  #
  # @return [Array<Module>]           @see #include_submodules in lib/emma.rb
  #
  def self.included(base)
    include_submodules(base, __FILE__)
  end

end
