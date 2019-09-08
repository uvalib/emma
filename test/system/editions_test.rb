# test/system/editions_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class EditionsTest < ApplicationSystemTestCase

=begin
  test 'editions - visit edition list' do
    run_test(__method__) do
      visit edition_index_path
      show_url
      assert_valid_index_page(:edition)
    end
  end
=end

end
