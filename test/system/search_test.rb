# test/system/search_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class SearchTest < ApplicationSystemTestCase

  PAGE_COUNT = 4

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'search - visit index' do
    run_test(__method__) do

      # Visit the first catalog titles index page.
      page = 0
      visit_index(:search, page: page) do
        show "PAGE #{page} = #{current_url}"
      end

      # Forward sequence of catalog titles index pages.
      while (page += 1) <= PAGE_COUNT
        visit_next_page(:search, page: page) do
          show "PAGE #{page} = #{current_url}"
        end
      end
      assert_not_first_page

      # Reverse sequence of catalog titles index pages.
      page = PAGE_COUNT
      while (page -= 1) >= 0
        visit_prev_page(:search, page: page) do
          show "PAGE #{page} = #{current_url}"
        end
      end
      assert_first_page

    end
  end

end
