# test/decorators/manifest_decorator_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_decorator_test_case'

class ManifestDecoratorTest < ApplicationDecoratorTestCase

  DEC = ManifestDecorator

  test 'manifest decorator - js_properties' do
    validate_js_properties(DEC)
  end

end
