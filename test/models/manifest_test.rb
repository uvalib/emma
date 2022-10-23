# test/models/manifest_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ManifestTest < ActiveSupport::TestCase

  test 'model - valid manifest' do
    run_test(__method__) do
      item = sample_manifest
      show item
      assert item.valid?
    end
  end

  test 'model - add items to manifest' do
    run_test(__method__) do
      item = sample_manifest
      item.manifest_items << manifest_items(:one)
      item.manifest_items << manifest_items(:two)
      show item
      assert item.valid?
    end
  end

end
