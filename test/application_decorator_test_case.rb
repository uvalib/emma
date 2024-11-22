# test/application_decorator_test_case.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

# Common base for decorator tests.
#
class ApplicationDecoratorTestCase < Draper::TestCase

  Draper::ViewContext.test_strategy :full

  # Check that properties used in asset pre-compilation are well-formed.
  #
  # @param [BaseDecorator, Class] dec
  #
  # @return [void]
  #
  def validate_js_properties(dec)
    dec  = dec.class unless dec.is_a?(Class)
    prop = dec.js_properties
    show_item { "keys = #{prop.keys.inspect}" }
    show_item { "actions = #{prop[:Action].keys.inspect}" }
    show_item { "js_properties = #{prop.pretty_inspect}" }
    refute_empty prop
  end

end
