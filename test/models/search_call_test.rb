# test/models/search_call_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchCallTest < ActiveSupport::TestCase

  test 'valid search call' do
    run_test(__method__) do
      item = sample_search_call
      show item
      assert item.valid?
    end
  end

end
