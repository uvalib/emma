# test/test_helper/system_tests/index.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for checking index pages and search results.
#
module TestHelper::SystemTests::Index

  include TestHelper::SystemTests::Action

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
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Integer]                       index
  # @param [Integer]                       total
  # @param [Integer]                       page
  # @param [Integer]                       size
  # @param [Hash]                          terms
  # @param [Hash]                          opt    To #assert_valid_action_page.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
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
    ctrlr = controller_name(model)
    prop  = property(ctrlr, :index)&.slice(:title, :heading)
    opt.reverse_merge!(prop) if prop.is_a?(Hash)
    if (terms = terms.presence)
      opt[:title] &&= "#{opt[:title]} - #{title_terms(ctrlr, **terms)} |"
    end

    # Validate page properties.
    assert_valid_action_page(ctrlr, :index, **opt)
    assert_search_terms(**terms)                    if terms
    assert_search_count(ctrlr, total: total, **opt) if terms || total

    # Validate pagination if provided.
    if index || page
      size  ||= Paginator.get_page_size(ctrlr)
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
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Hash]                          terms
  #
  # @return [String]
  #
  def title_terms(model, **terms)
    ctrlr = controller_name(model)
    SearchTermsHelper.search_terms(ctrlr, pairs: terms).values.map { |term|
      if term.query?
        array_string(term.names, inspect: true)
      elsif term.present?
        "#{term.label}: %s" % array_string(term.values, inspect: true)
      end
    }.compact.join(' | ')
  end

  # Assert that each active search term is displayed on the index page.
  #
  # @param [Hash] terms
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
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
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Integer]                       total
  # @param [String]                        records
  #
  # @raise [Minitest::Assertion]      If the count is not displayed.
  # @raise [RuntimeError]             If *records* is not given or found.
  #
  # @return [true]
  #
  def assert_search_count(model, total: nil, records: nil, **)
    ctrlr     = controller_name(model)
    records ||= property(ctrlr, :index, :count)
    assert records, ->() { "#{ctrlr} unit could not be determined" }
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
  # @raise [Minitest::Assertion]
  #
  # @return [void]
  #
  # @yield Test code to run while on the page.
  # @yieldreturn [void]
  #
  def visit_index(target, action: :index, model: nil, **opt)
    if target.is_a?(Symbol)
      terms = opt[:terms].presence || {}
      u_opt = opt.extract!(:limit, :offset).merge!(terms)
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
    assert_valid_index_page(model, **opt)
    screenshot
  end

  # visit_each_show_page
  #
  # @param [Symbol,String,Class,Model,nil] model
  # @param [String]                        entry_css
  #
  # @raise [Minitest::Assertion]
  #
  # @return [void]
  #
  # @yield [index, title] Exposes each visited page for additional actions.
  # @yieldparam [Integer] index
  # @yieldparam [String]  title
  # @yieldreturn [void]
  #
  # @note Currently unused
  #
  def visit_each_show_page(model, entry_css: nil, &blk)
    ctrlr       = controller_name(model)
    entry_css ||= property(ctrlr, :index, :entry_css)
    assert entry_css, ->() { "#{ctrlr} entry_css could not be determined" }
    entry_count = all(entry_css).size
    max_index = entry_count - 1
    (0..max_index).each do |index|
      visit_show_page(ctrlr, entry_css: entry_css, index: index) do |title|
        blk&.call(index, title)
      end
      go_back # Return to index page.
    end
    true
  end

end
