# test/decorators/search_title_decorator_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_decorator_test_case'

class SearchTitleDecoratorTest < ApplicationDecoratorTestCase

  DEC = SearchTitleDecorator

  test 'search_title decorator - js_properties' do
    validate_js_properties(DEC)
  end

end
