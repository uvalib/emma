# test/test_helper/system_tests/pagination.rb
#
# frozen_string_literal: true
# warn_indent:           true

#require_relative '_common'

# Support for checking pagination.
#
module TestHelper::SystemTests::Pagination

  include TestHelper::SystemTests::Common

  NEXT_LABEL = 'NEXT'
  PREV_LABEL = 'PREV'

  include Capybara::Minitest::Assertions unless ONLY_FOR_DOCUMENTATION

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
  def visit_next_page
    click_link NEXT_LABEL, match: :first
  end

  # Visit the previous page of search results.
  #
  def visit_prev_page
    click_link PREV_LABEL, match: :first
  end

end
