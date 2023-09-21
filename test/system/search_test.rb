# test/system/search_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class SearchTest < ApplicationSystemTestCase

  CONTROLLER   = :search
  PARAMS       = { controller: CONTROLLER }.freeze

  PAGE_COUNT   = 4
  TITLE_SEARCH = 'man'

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search - for title' do
    action    = :index
    terms     = { title: TITLE_SEARCH }
    params    = PARAMS.merge(action: action, **terms)

    start_url = url_for(**params)

    run_test(__method__) do

      # Visit the first search results page.
      visit start_url
      index = 0

      # Forward sequence of search results pages.
      while index < PAGE_COUNT
        show_page(index, base_url: start_url)
        click_on NEXT_LABEL, match: :first
        index += 1
      end
      assert_not_first_page

      # Reverse sequence of search results pages.
      while index > 0
        show_page(index, base_url: start_url)
        click_on PREV_LABEL, match: :first
        index -= 1
      end
      assert_first_page

      # Back on the first search results page.
      show_page(index, base_url: start_url)

    end
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # Await the indicated page then output its :prev and :next links.
  #
  # @param [Integer] index
  # @param [String]  base_url
  # @param [String]  expected_url
  # @param [Integer] max            Maximum number of attempts to make.
  #
  # @return [void]
  #
  # == Implementation Notes
  # Sometimes #wait_for_page succeeds but, in fact, the page is not actually
  # rendered.  For that reason, there is an extra layer of indirection which
  # re-waits for the page if neither :prev nor :next can be found.
  #
  def show_page(
    index,
    base_url:     nil,
    expected_url: nil,
    max:          DEFAULT_WAIT_MAX_PASS
  )
    page = (index + 1 unless index.zero?)
    expected_url ||= make_path(base_url, page: page)

    links = {}
    while links.values.all?(&:nil?) && (max -= 1).positive?
      next unless wait_for_page(expected_url, fatal: false)
      links = { PREV: PREV_LABEL, NEXT: NEXT_LABEL }
      links.transform_values! { |label| first(:link, label, minimum: 0) }
    end

    current = url_without_port(current_url)
    if links.values.all?(&:nil?)
      flunk "Browser on page #{current} and not on #{expected_url}"
    else
      links.transform_values! do |link|
        link = link[:href] if link.is_a?(Capybara::Node::Element)
        link&.include?('/') ? url_without_port(link) : link.inspect
      end
      links = links.map { |name, link| "#{name} = #{link}" }
      show ["PAGE #{page || 1} = #{current}", *links].join(' | ')
    end
  end

end
