# test/decorators/user_decorator_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_decorator_test_case'

class UserDecoratorTest < ApplicationDecoratorTestCase

  DEC = UserDecorator

  test 'user decorator - js_properties' do
    validate_js_properties(DEC)
  end

end
