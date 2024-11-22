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
  unless ONLY_FOR_DOCUMENTATION
    include Capybara::Minitest::Assertions
  end
  # :nocov:

  NEXT_LABEL = 'NEXT'
  PREV_LABEL = 'PREV'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that this is the first page of search results.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def assert_first_page
    assert_no_link PREV_LABEL
  end

  # Assert that this is the last page of search results.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  # :nocov:
  def assert_last_page
    assert_no_link NEXT_LABEL
  end
  # :nocov:

  # Assert that this is not the first page of search results.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def assert_not_first_page
    assert_link PREV_LABEL
  end

  # Assert that this is not the first page of search results.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  # :nocov:
  def assert_not_last_page
    assert_link NEXT_LABEL
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Visit the next page of search results.
  #
  # @param [Symbol] ctrlr
  # @param [Hash]   opt               Passed to #assert_valid_index_page.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @yield Test code to run while on the page.
  # @yieldreturn [void]
  #
  # @note Currently unused.
  #
  def visit_next_page(ctrlr, **opt)
    click_on NEXT_LABEL, match: :first
    if block_given?
      yield
    else
      show_url
    end
    assert_valid_index_page(ctrlr, **opt)
  end

  # Visit the previous page of search results.
  #
  # @param [Symbol] ctrlr
  # @param [Hash]   opt               Passed to #assert_valid_index_page.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @yield Test code to run while on the page.
  # @yieldreturn [void]
  #
  # @note Currently unused.
  #
  def visit_prev_page(ctrlr, **opt)
    click_on PREV_LABEL, match: :first
    if block_given?
      yield
    else
      show_url
    end
    assert_valid_index_page(ctrlr, **opt)
  end

end
