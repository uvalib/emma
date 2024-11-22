# test/decorators/search_call_decorator_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_decorator_test_case'

class SearchCallDecoratorTest < ApplicationDecoratorTestCase

  DEC = SearchCallDecorator

  test 'search_call decorator - js_properties' do
    validate_js_properties(DEC)
  end

end
