# test/test_helper/system_tests/index.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for checking index pages and search results.
#
module TestHelper::SystemTests::Index

  include TestHelper::SystemTests::Action
  include SearchTermsHelper # for :search_terms

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  SEARCH_COUNT_CLASS = '.search-count'
  SEARCH_TERMS_CLASS = '.search-terms' # TODO: test on header facet selections
  VALUE_SELECTOR     = "#{SEARCH_TERMS_CLASS} .term .value"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that the current page is a valid index page.
  #
  # @param [Symbol]  model
  # @param [Integer] index
  # @param [Integer] total
  # @param [Integer] page
  # @param [Integer] size
  # @param [Hash]    terms
  # @param [Hash]    opt              Passed to #assert_valid_action_page.
  #
  # @return [true]
  #
  # @raise [Minitest::Assertion]
  #
  def assert_valid_index_page(
    model,
    index: nil,
    total: nil,
    page:  nil,
    size:  nil,
    terms: nil,
    **opt
  )
    terms = terms.presence
    prop  = property(model, :index)&.slice(:title, :heading)
    opt.reverse_merge!(prop) if prop.present?
    if (terms = terms.presence)
      opt[:title] &&= "#{opt[:title]} - #{title_terms(model, **terms)} |"
    end

    # Validate page properties.
    assert_valid_action_page(model, :index, **opt)
    assert_search_terms(**terms)                    if terms
    assert_search_count(model, total: total, **opt) if terms || total

    # Validate pagination if provided.
    if index || page
      size  ||= Paginator.get_page_size(controller: model)
      page  ||= (index - 1) / size
      index ||= (page * size) + 1
      (page  <= 0)    ? assert_first_page : assert_not_first_page
      (index <= size) ? assert_first_page : assert_not_first_page
      # assert_selector 'h2.number', text: index.to_s # TODO: Page number?
    end
    true
  end

  # Generate a string for search terms as they would appear in the '<title>'
  # element.
  #
  # @param [Symbol] model
  # @param [Hash]   terms
  #
  # @return [String]
  #
  def title_terms(model, **terms)
    search_terms(model, pairs: terms).map { |_field, term|
      next if term.blank?
      if term.query?
        array_string(term.names, inspect: true)
      else
        "#{term.label}: " + array_string(term.values, inspect: true)
      end
    }.compact.join(' | ')
  end

  # Assert that each active search term is displayed on the index page.
  #
  # @param [Hash] terms
  #
  # @return [true]
  #
  # @raise [Minitest::Assertion]
  #
  # NOTE: The active search terms are no longer displayed on the page.
  #
  #--
  # noinspection RubyDeadCode
  #++
  def assert_search_terms(**terms)
    return true # TODO: test on header facet selections
    terms.each_value do |value|
      assert_selector VALUE_SELECTOR, text: value
    end
    true
  end

  # Assert that a search count is displayed on the index page.
  #
  # @param [Symbol]  model
  # @param [Integer] total
  # @param [String]  records
  #
  # @return [true]
  #
  # @raise [Minitest::Assertion]      If the count is not displayed.
  # @raise [RuntimeError]             If *records* is not given or found.
  #
  def assert_search_count(model, total: nil, records: nil, **)
    records ||= property(model, :index, :count)
    raise "#{model} unit could not be determined" unless records
    records = "#{total} #{records}".strip if total.present?
    assert_selector SEARCH_COUNT_CLASS, text: records
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # visit_index
  #
  # @param [Symbol, String] target
  # @param [Symbol]         action
  # @param [Symbol, nil]    model
  # @param [Hash]           opt       Passed to #assert_valid_index_page.
  #
  # @return [true]
  #
  # @raise [Minitest::Assertion]
  #
  # @yield Test code to run while on the page.
  # @yieldreturn [void]
  #
  def visit_index(target, action: :index, model: nil, **opt)
    if target.is_a?(Symbol)
      u_opt = extract_hash!(opt, :limit, :offset)
      u_opt.merge!(opt[:terms]) if opt[:terms].present?
      url   = url_for(controller: target, action: action, **u_opt)
    else
      url, target = [target, nil]
    end
    visit url
    if block_given?
      yield
    else
      show_url
    end
    model ||= target || this_controller
    # noinspection RubyMismatchedArgumentType
    assert_valid_index_page(model, **opt)
    success_screenshot
  end

  # visit_each_show_page
  #
  # @param [Symbol] model
  # @param [String] entry_css
  #
  # @return [void]
  #
  # @raise [Minitest::Assertion]
  #
  # @yield [index, title] Exposes each visited page for additional actions.
  # @yieldparam [Integer] index
  # @yieldparam [String]  title
  # @yieldreturn [void]
  #
  def visit_each_show_page(model, entry_css: nil, &block)
    entry_css ||= property(model, :index, :entry_css)
    raise "#{model} entry_css could not be determined" unless entry_css
    entry_count = all(entry_css).size
    max_index = entry_count - 1
    (0..max_index).each do |index|
      visit_show_page(model, entry_css: entry_css, index: index) do |title|
        block&.call(index, title)
      end
      go_back # Return to index page.
    end
    true
  end

end
