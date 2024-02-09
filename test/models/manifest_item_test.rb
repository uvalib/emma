# test/models/manifest_item_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ManifestItemTest < ActiveSupport::TestCase

  test 'model - valid manifest item' do
    run_test(__method__) do
      item = manifest_items(:example)
      show_item(item)
      assert item.valid?
    end
  end

end
