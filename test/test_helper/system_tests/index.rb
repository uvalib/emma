# test/test_helper/system_tests/index.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for checking index pages and search results.
#
module TestHelper::SystemTests::Index

  include TestHelper::SystemTests::Common

  include PaginationHelper

  SEARCH_COUNT_CLASS = '.search-count'
  SEARCH_TERMS_CLASS = '.search-terms'
  VALUE_SELECTOR     = "#{SEARCH_TERMS_CLASS} .term .value"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that the current page is a valid index page.
  #
  # @param [Symbol, nil] model
  # @param [String]      title
  # @param [String]      heading
  # @param [Integer]     index
  # @param [Integer]     page
  # @param [Integer]     size
  # @param [Hash]        terms
  # @param [Hash]        opt          Passed to #assert_valid_page.
  #
  # @return [void]
  #
  def assert_valid_index_page(
    model  = nil,
    title:   nil,
    heading: nil,
    index:   nil,
    page:    nil,
    size:    nil,
    terms:   nil,
    **opt
  )
    # Validate page properties.
    title   ||= PROPERTY.dig(model, :index, :title)
    title   &&= "#{title} - #{title_terms(**terms)} |" if terms.present?
    heading ||= PROPERTY.dig(model, :index, :heading)
    assert_valid_page title: title, heading: heading, **opt

    # Validate pagination if provided.
    if index || page
      size  ||= get_page_size(controller: model)
      page  ||= (index - 1) / size
      index ||= (page * size) + 1
      (page  <= 0)    ? assert_first_page : assert_not_first_page
      (index <= size) ? assert_first_page : assert_not_first_page
      assert_selector 'h2.number', text: index.to_s
    end

    # For search results, *terms* will at least be an empty hash.
    unless terms.nil?
      assert_search_terms(terms)
      assert_search_count(model, **opt)
    end
  end

  # Generate a string for search terms as they would appear in the <title>
  # element.
  #
  # @param [Hash]
  #
  # @return [String]
  #
  def title_terms(**terms)
    terms.map { |k, v|
      n = v.is_a?(Enumerable) ? v.size : 1
      k = inflection(k.to_s.capitalize, n)
      v = strip_quotes(v)
      "#{k}: #{quote(v)}"
    }.join('; ')
  end

  # Assert that each active search term is displayed on the index page.
  #
  # @param [Hash] terms
  #
  # @return [void]
  #
  def assert_search_terms(**terms)
    terms.each_value do |value|
      assert_selector VALUE_SELECTOR, text: value
    end
  end

  # Assert that a search count is displayed on the index page.
  #
  # @param [Symbol, nil] model
  # @param [Integer]     total
  # @param [String]      count
  #
  # @return [void]
  #
  def assert_search_count(model, total: nil, count: nil)
    count ||= PROPERTY.dig(model, :index, :count)
    if count.present?
      count = "#{total} #{count}" if total.present?
      assert_selector SEARCH_COUNT_CLASS, text: count
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # visit_index
  #
  # @param [Symbol, String] url
  # @param [Hash]           opt       Passed to #assert_valid_index_page.
  #
  # @return [void]
  #
  def visit_index(url, **opt)
    if url.is_a?(Symbol)
      model = url
      terms = opt[:terms] || {}
      url   = url_for(controller: model, action: :index, **terms)
    else
      model = nil
    end
    visit url
    if block_given?
      yield
    else
      show_url
    end
    # noinspection RubyYardParamTypeMatch
    assert_valid_index_page(model, **opt)
  end

  # visit_each_show_page
  #
  # @param [Symbol] model
  # @param [String] entry_class
  #
  # @yield [index, title] Exposes each visited page for additional actions.
  # @yieldparam [Integer] index
  # @yieldparam [String]  title
  # @yieldreturn [void]
  #
  # @return [void]
  #
  def visit_each_show_page(model, entry_class: nil)
    entry_class ||= PROPERTY.dig(model, :index, :entry_class)
    entry_count = all(entry_class).size
    max_index = entry_count - 1
    (0..max_index).each do |index|
      visit_show_page(model, entry_class: entry_class, index: index) do |title|
        yield(index, title) if block_given?
      end
      go_back # Return to index page.
    end
  end

end
