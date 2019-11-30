# test/system/titles_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class TitlesTest < ApplicationSystemTestCase

  PAGE_COUNT = 4

  # There were 37125 results for this search as the anonymous user as of
  # 2019-09-02.
  TITLE_SEARCH_TERM = 'cat'

  # There were 952 results for this search as the anonymous user as of
  # 2019-09-02.
  EXACT_TITLE_SEARCH_TERM = '"cat"'

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'catalog titles - visit index' do
    run_test(__method__) do

      # Visit the first catalog titles index page.
      page = 0
      visit_index(:title, page: page) do
        show "PAGE #{page} = #{current_url}"
      end

      # Forward sequence of catalog titles index pages.
      while (page += 1) <= PAGE_COUNT
        visit_next_page(:title, page: page) do
          show "PAGE #{page} = #{current_url}"
        end
      end
      assert_not_first_page

      # Reverse sequence of catalog titles index pages.
      page = PAGE_COUNT
      while (page -= 1) >= 0
        visit_prev_page(:title, page: page) do
          show "PAGE #{page} = #{current_url}"
        end
      end
      assert_first_page

    end
  end

  test 'catalog titles - visit each show page' do
    run_test(__method__) do

      # Visit the first catalog titles index page.
      visit_index :title
      assert_first_page

      # Visit each entry on the first catalog titles index page.
      visit_each_show_page(:title) do |index, title, _entry|
        show "ENTRY #{index} - #{title}"
      end

      # Should be back on first catalog title index page.
      show_url
      assert_valid_index_page(:title)
      assert_first_page

    end
  end

  test 'catalog titles - search for title' do
    run_test(__method__) do

      terms = { title: TITLE_SEARCH_TERM }
      show "Terms: #{terms.inspect}"

      # Search for term(s).
      visit_index :title, terms: terms
      assert_first_page

      # Go to next page of results.
      visit_next_page :title, terms: terms
      assert_not_first_page

      # Visit the first entry.
      visit_show_page(:title) do |title|
        parts = title.downcase
        term  = terms.values.first.downcase
        show "TERM = #{term}"
        assert parts.include?(term)
      end

      # Go back to the index page.
      go_back
      show_url
      assert_valid_index_page(:title, terms: terms)
      assert_not_first_page

    end
  end

  test 'catalog titles - search for title word' do
    run_test(__method__) do

      terms = { title: EXACT_TITLE_SEARCH_TERM }
      show "Terms: #{terms.inspect}"

      # Search for term(s).
      visit_index :title, terms: terms
      assert_first_page

      # Go to next page of results.
      visit_next_page :title, terms: terms
      assert_not_first_page

      # Visit the first entry.
      visit_show_page(:title) do |title|
        parts = title.downcase.split(/[[:space:][:punct:]]+/)
        term  = strip_quotes(terms.values.first.downcase)
        show "TERM = #{term}"
        assert parts.any? { |part| part == term }
      end

      # Go back to the index page.
      go_back
      show_url
      assert_valid_index_page(:title, terms: terms)
      assert_not_first_page

    end
  end

end
