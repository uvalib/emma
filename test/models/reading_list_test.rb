# test/models/reading_list_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ReadingListTest < ActiveSupport::TestCase

  test 'model - valid reading list' do
    run_test(__method__) do
      item = sample_reading_list
      show item
      assert item.valid?
    end
  end

  test 'model - add title to reading list' do
    run_test(__method__) do
      item = sample_reading_list
      item.titles << sample_title
      show item
      assert item.valid?
    end
  end

end
