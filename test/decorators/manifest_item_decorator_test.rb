# test/decorators/manifest_item_decorator_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_decorator_test_case'

class ManifestItemDecoratorTest < ApplicationDecoratorTestCase

  DEC = ManifestItemDecorator

  test 'manifest_item decorator - js_properties' do
    validate_js_properties(DEC)
  end

end
