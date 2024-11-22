# test/decorators/account_decorator_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_decorator_test_case'

class AccountDecoratorTest < ApplicationDecoratorTestCase

  DEC = AccountDecorator

  test 'account decorator - js_properties' do
    validate_js_properties(DEC)
  end

end
