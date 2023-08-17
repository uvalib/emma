# test/models/search_result_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchResultTest < ActiveSupport::TestCase

  test 'model - valid search result' do
    run_test(__method__) do
      item = search_results(:example)
      show item
      assert item.valid?
    end
  end

end
