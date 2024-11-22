# test/decorators/org_decorator_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_decorator_test_case'

class OrgDecoratorTest < ApplicationDecoratorTestCase

  DEC = OrgDecorator

  test 'org decorator - js_properties' do
    validate_js_properties(DEC)
  end

end
