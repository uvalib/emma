# test/models/search_result_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_model_test_case'

class SearchResultTest < ApplicationModelTestCase

  test 'model - valid search result' do
    run_test(__method__) do
      item = search_results(:example)
      show_item(item)
      assert item.valid?
    end
  end

end
