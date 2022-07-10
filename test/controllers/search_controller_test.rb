# test/controllers/search_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :search
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search index - no search' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        next unless allowed_format(fmt, only: :html)
        url = search_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end
  end

  test 'search index - sample search' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    item    = sample_search_call
    url_opt = item.query.symbolize_keys
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = search_index_url(**url_opt, format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end
  end

  test 'search show - details search result item' do
    action  = :show
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    item    = sample_search_result
    url_opt = { id: record_id(item) }
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = search_url(**url_opt, format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end unless not_applicable 'Bookshare API does not support this'
    # NOTE: Per SearchController#show, this endpoint can't be implemented.
  end

end
