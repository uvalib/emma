# test/system/titles_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class TitlesTest < ApplicationSystemTestCase

  PAGE_SIZE  = 10
  PAGE_COUNT = 4

  # There were 37125 results for this search as the anonymous user as of
  # 2019-09-02.
  TITLE_SEARCH_TERM = 'cat'

  # There were 952 results for this search as the anonymous user as of
  # 2019-09-02.
  EXACT_TITLE_SEARCH_TERM = '"cat"'

  # ===========================================================================
  # :section: Tests
  # ===========================================================================

  test 'catalog titles - visit index' do
    run_test(__method__) do

      page = 0

      # Visit the first catalog titles index page.
      visit title_index_url
      show "PAGE #{page} = #{current_url}"
      assert_valid_index_page(:title)
      assert_first_page
      assert_selector 'h2.number', text: '1'

      # Forward sequence of catalog titles index pages.
      while (page += 1) <= PAGE_COUNT
        visit_next_page
        show "PAGE #{page} = #{current_url}"
        assert_valid_index_page(:title)
        assert_selector 'h2.number', text: ((PAGE_SIZE * page) + 1).to_s
      end
      assert_not_first_page

      # Reverse sequence of catalog titles index pages.
      page = PAGE_COUNT
      while (page -= 1) >= 0
        visit_prev_page
        show "PAGE #{page} = #{current_url}"
        assert_valid_index_page(:title)
        assert_selector 'h2.number', text: ((PAGE_SIZE * page) + 1).to_s
      end
      assert_first_page

    end
  end

  test 'catalog titles - visit each show page' do
    run_test(__method__) do

      # Visit the first catalog titles index page.
      visit title_index_url
      show_url
      assert_valid_index_page(:title)
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
      visit title_index_url(**terms)
      show_url
      assert_valid_search_results(:title, terms: terms)
      assert_first_page

      # Go to next page of results.
      visit_next_page
      show_url
      assert_valid_search_results(:title, terms: terms)
      assert_not_first_page

      # Visit the first entry.
      title = visit_show_page(:title)
      parts = title.downcase
      term  = terms.values.first.downcase
      show "TERM = #{term}"
      assert parts.include?(term)

      # Go back to the index page.
      go_back
      show_url
      assert_valid_search_results(:title, terms: terms)
      assert_not_first_page

    end
  end

  test 'catalog titles - search for title word' do
    run_test(__method__) do

      terms = { title: EXACT_TITLE_SEARCH_TERM }
      show "Terms: #{terms.inspect}"

      # Search for term(s).
      visit title_index_url(**terms)
      show_url
      assert_valid_search_results(:title, terms: terms)
      assert_first_page

      # Go to next page of results.
      visit_next_page
      show_url
      assert_valid_search_results(:title, terms: terms)
      assert_not_first_page

      # Visit the first entry.
      title = visit_show_page(:title)
      parts = title.downcase.split(/[[:space:]]|[[:punct:]]/)
      term  = strip_quotes(terms.values.first.downcase)
      show "TERM = #{term}"
      assert parts.any? { |part| part == term }

      # Go back to the index page.
      go_back
      show_url
      assert_valid_search_results(:title, terms: terms)
      assert_not_first_page

    end
  end

end
