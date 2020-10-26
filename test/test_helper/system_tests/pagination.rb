# test/test_helper/system_tests/pagination.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for checking pagination.
#
module TestHelper::SystemTests::Pagination

  include TestHelper::SystemTests::Index

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  include Capybara::Minitest::Assertions unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  NEXT_LABEL = 'NEXT'
  PREV_LABEL = 'PREV'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that this is the first page of search results.
  #
  def assert_first_page
    assert_no_link PREV_LABEL
  end

  # Assert that this is the last page of search results.
  #
  def assert_last_page
    assert_no_link NEXT_LABEL
  end

  # Assert that this is not the first page of search results.
  #
  def assert_not_first_page
    assert_link PREV_LABEL
  end

  # Assert that this is not the first page of search results.
  #
  def assert_not_last_page
    assert_link NEXT_LABEL
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Visit the next page of search results.
  #
  # @param [Symbol, nil] model
  # @param [Hash]        opt          Passed to #assert_valid_index_page.
  #
  # @return [void]
  #
  # @yield Test code to run while on the page.
  # @yieldreturn [void]
  #
  def visit_next_page(model, **opt)
    click_link NEXT_LABEL, match: :first
    if block_given?
      yield
    else
      show_url
    end
    assert_valid_index_page(model, **opt)
  end

  # Visit the previous page of search results.
  #
  # @param [Symbol, nil] model
  # @param [Hash]        opt          Passed to #assert_valid_index_page.
  #
  # @return [void]
  #
  # @yield Test code to run while on the page.
  # @yieldreturn [void]
  #
  def visit_prev_page(model, **opt)
    click_link PREV_LABEL, match: :first
    if block_given?
      yield
    else
      show_url
    end
    assert_valid_index_page(model, **opt)
  end

end
