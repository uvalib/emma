# test/system/categories_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class CategoriesTest < ApplicationSystemTestCase

  test 'categories - visit index' do
    run_test(__method__) do

      # Visit the first category page.
      visit_index :category
      assert_first_page

      # Visit the next category page.
      visit_next_page :category
      assert_not_first_page

      # Return to the first category page.
      visit_prev_page :category
      assert_first_page

      # Visit catalog titles page for first category.
      link  = find('.category-list-item', match: :first).find('a')
      terms = { category: link.text }
      link.click
      show_url
      assert_valid_index_page(:title, terms: terms)

      # Return to the category page.
      go_back
      show_url
      assert_valid_index_page(:category)

    end
  end

  test 'categories - visit all index pages' do
    run_test(__method__) do

      # Visit the first category page.
      visit_index :category
      assert_first_page

      # Visit the rest of the category pages in order.
      while has_link?(NEXT_LABEL) do
        visit_next_page :category
      end
      assert_last_page

      # Visit all previous category pages in reverse order.
      while has_link?(PREV_LABEL) do
        visit_prev_page :category
      end
      assert_first_page

    end
  end

end
