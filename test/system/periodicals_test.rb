# test/system/periodicals_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class PeriodicalsTest < ApplicationSystemTestCase

  PAGE_COUNT = 2

  # There were 29 results for this search as the anonymous user as of
  # 2019-09-02.
  PERIODICAL_TITLE_SEARCH_TERM = 'Times'

  # There were 0 results for this search as the anonymous user as of
  # 2019-09-02 (but there should have been 2).
  # noinspection RubyConstantNamingConvention
  PERIODICAL_EXACT_TITLE_SEARCH_TERM = quote('west')

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'periodicals - visit index' do
    run_test(__method__) do

      # Visit the first periodicals index page.
      page = 0
      visit_index(:periodical, page: page) do
        show "PAGE #{page} = #{current_url}"
      end

      # Forward sequence of periodicals index pages.
      while (page += 1) <= PAGE_COUNT
        visit_next_page(:periodical, page: page) do
          show "PAGE #{page} = #{current_url}"
        end
      end
      assert_not_first_page

      # Reverse sequence of periodicals index pages.
      page = PAGE_COUNT
      while (page -= 1) >= 0
        visit_prev_page(:periodical, page: page) do
          show "PAGE #{page} = #{current_url}"
        end
      end
      assert_first_page

    end
  end

  test 'periodicals - visit each show page' do
    run_test(__method__) do

      # Visit the first periodicals index page.
      visit_index :periodical
      assert_first_page

      # Visit each entry on the first periodicals index page.
      visit_each_show_page(:periodical) do |index, title, _entry|
        show "ENTRY #{index} - #{title}"
      end

      # Should be back on first periodicals index page.
      show_url
      assert_valid_index_page(:periodical)
      assert_first_page

    end
  end

  test 'periodicals - search for title' do
    run_test(__method__) do

      terms = { title: PERIODICAL_TITLE_SEARCH_TERM }
      show "Terms: #{terms.inspect}"

      # Search for term(s).
      visit_index :periodical, terms: terms
      assert_first_page

      # Go to next page of results.
      visit_next_page :periodical, terms: terms
      assert_not_first_page

      # Visit the first entry.
      visit_show_page(:periodical) do |title|
        parts = title.downcase
        term  = terms.values.first.to_s.downcase
        show "TERM = #{term}"
        assert parts.include?(term)
      end

      # Go back to the index page.
      go_back
      show_url
      assert_valid_index_page(:periodical, terms: terms)
      assert_not_first_page

    end
  end

=begin # TODO: The Bookshare API does not seem to support this.
  test 'periodicals - search for title word' do
    run_test(__method__) do

      terms = { title: PERIODICAL_EXACT_TITLE_SEARCH_TERM }
      show "Terms: #{terms.inspect}"

      # Search for term(s).
      visit_index :periodical, terms: terms
      assert_first_page

      # Go to next page of results.
      visit_next_page :periodical, terms: terms
      assert_not_first_page

      # Visit the first entry.
      visit_show_page(:periodical) do |title|
        parts = title.downcase.split(/[[:space:][:punct:]]+/)
        term  = strip_quotes(terms.values.first.downcase)
        show "TERM = #{term}"
        assert parts.any? { |part| part == term }
      end

      # Go back to the index page.
      go_back
      show_url
      assert_valid_search_results(:periodical, terms: terms)
      assert_not_first_page

    end
  end
=end

end
