# test/controllers/search_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'search'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_DSO].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = [].freeze # Not relevant for this controller.

  TEST_READERS = [ANONYMOUS]  # TODO: remove - testing
  TEST_FORMATS = %i[html]     # TODO: remove - testing

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search index - no search' do
    options = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = search_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  test 'search index - sample search' do
    search  = sample_search_call.query.title # TODO: build search from entry
    options = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = search_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  test 'search show - details search result item' do
    item    = sample_search_call.results.first.repositoryRecordId # TODO: extract search result
    options = OPTIONS.merge(test: __method__, action: 'show')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = search_url(id: item, format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

end
