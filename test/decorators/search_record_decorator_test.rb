# test/decorators/search_record_decorator_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_decorator_test_case'

class SearchRecordDecoratorTest < ApplicationDecoratorTestCase

  DEC = SearchRecordDecorator

  test 'search_record decorator - js_properties' do
    validate_js_properties(DEC)
  end

end
