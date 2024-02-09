# test/controllers/search_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :search
  PARAMS       = { controller: CONTROLLER }.freeze
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = CORE_TEST_USERS
  TEST_READERS = TEST_USERS

  READ_FORMATS = :all

  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search index - no search' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      u_opt = options

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: :html)
      end
    end
  end

  test 'search index - sample search' do
    action  = :index
    item    = search_calls(:example)
    params  = PARAMS.merge(action: action).merge!(item.query.symbolize_keys)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      u_opt = options

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'search show - details search result item' do
    action  = :show
    item    = search_results(:example)
    params  = PARAMS.merge(action: action, id: record_id(item))
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      u_opt = options

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end unless not_applicable('EMMA Unified Search API does not support this')
    # NOTE: Per SearchController#show, this endpoint can't be implemented.
  end

end
