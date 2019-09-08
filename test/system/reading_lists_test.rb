# test/system/reading_lists_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ReadingListsTest < ApplicationSystemTestCase

  test 'reading lists - visit index' do
    run_test(__method__) do
      visit reading_list_index_path
      assert_flash alert: 'You need to sign in'
    end
  end

end
