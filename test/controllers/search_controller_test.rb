# test/controllers/search_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class SearchControllerTest < ApplicationControllerTestCase

  CTRLR = :search
  PRM   = { controller: CTRLR }.freeze
  OPT   = { controller: CTRLR, sign_out: false }.freeze

  TEST_READERS = CORE_TEST_USERS

  READ_FORMATS = :all

  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search index - no search' do
    action  = :index
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      u_opt = options
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: :html)
      end
    end
  end

  test 'search index - sample search' do
    action  = :index
    item    = search_calls(:example)
    params  = PRM.merge(action: action).merge!(item.query.symbolize_keys)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      u_opt = options
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

=begin # NOTE: Per SearchController#show, this endpoint can't be implemented.
  test 'search show - details search result item' do
    action  = :show
    item    = search_results(:example)
    params  = PRM.merge(action: action, id: record_id(item))
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      u_opt = options
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end unless not_applicable('EMMA Unified Search API does not support this')
  end
=end

end
