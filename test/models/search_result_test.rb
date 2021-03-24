# test/models/search_result_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchResultTest < ActiveSupport::TestCase

  test 'valid search result' do
    run_test(__method__) do
      item = sample_search_result
      show item
      assert item.valid?
    end
  end

end
