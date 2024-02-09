# test/models/search_call_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchCallTest < ActiveSupport::TestCase

  test 'model - valid search call' do
    run_test(__method__) do
      item = search_calls(:example)
      show_item(item)
      assert item.valid?
    end
  end

end
