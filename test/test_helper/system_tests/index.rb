# test/test_helper/system_tests/index.rb
#
# frozen_string_literal: true
# warn_indent:           true

#require_relative '_common'

# Support for checking index pages and search results.
#
module TestHelper::SystemTests::Index

  include TestHelper::SystemTests::Common

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
  # @param [Hash]        terms
  #
  def assert_valid_index_page(
    model = nil,
    title:   nil,
    heading: nil,
    terms:   nil
  )
    title   ||= PROPERTY.dig(model, :index, :title)
    heading ||= PROPERTY.dig(model, :index, :heading)
    title = "#{title} - #{title_terms(**terms)}" if title && terms.present?
    assert_title    "#{title} |"                 if title
    assert_selector 'h1', text: heading          if heading
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
      v = %Q("#{strip_quotes(v)}")
      "#{k}: #{v}"
    }.join('; ')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that the current page is a valid search results page.
  #
  # @param [Symbol, nil] model
  # @param [Hash]        terms
  # @param [Integer]     total
  # @param [String]      count
  # @param [Hash]        opt          @see #assert_valid_index_page
  #
  def assert_valid_search_results(
    model = nil,
    terms:  nil,
    total:  nil,
    count:  nil,
    **opt
  )
    assert_valid_index_page(model, terms: terms, **opt)
    assert_search_terms(terms) if terms.present?
    count ||= PROPERTY.dig(model, :index, :count)
    if count.present?
      count = "#{total} #{count}" if total.present?
      assert_selector SEARCH_COUNT_CLASS, text: count
    end
  end

  # Assert that each active search term is displayed on the index page.
  #
  # @param [Hash] terms
  #
  def assert_search_terms(**terms)
    terms.each_value do |value|
      assert_selector VALUE_SELECTOR, text: value
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # visit_each_show_page
  #
  # @param [Symbol, nil] model
  # @param [String]      entry_class
  #
  # @yield [index, title] Exposes each visited page for additional actions.
  # @yieldparam [Integer] index
  # @yieldparam [String]  title
  # @yieldreturn [void]
  #
  # @return [void]
  #
  def visit_each_show_page(model = nil, entry_class: nil)
    entry_class ||= PROPERTY.dig(model, :index, :entry_class)
    entry_count = all(entry_class).size
    max_index = entry_count - 1
    (0..max_index).each do |index|
      title = visit_show_page(model, index: index, entry_class: entry_class)
      yield(index, title) if block_given?
      go_back # Return to index page.
    end
  end

end
