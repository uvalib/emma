# test/models/manifest_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_model_test_case'

class ManifestTest < ApplicationModelTestCase

  test 'model - valid manifest' do
    run_test(__method__) do
      item = manifests(:example)
      show_item(item)
      assert item.valid?
    end
  end

  test 'model - add items to manifest' do
    run_test(__method__) do
      item = manifests(:example).dup
      item.manifest_items << manifest_items(:one)
      item.manifest_items << manifest_items(:two)
      show_item(item)
      assert item.valid?
    end
  end

end
