# test/controllers/search_call_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchCallControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :search_call
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso developer].freeze
  TEST_READERS = TEST_USERS

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search call index - no search' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, SearchCall)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = search_call_index_url(format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt)
      end
    end
  end

  test 'search call index - sample search' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_search_call
    url_opt = { search_call: item }
    @readers.each do |user|
      able  = can?(user, action, SearchCall)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = search_call_index_url(**url_opt, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt)
      end
    end
  end

  test 'search call show - details search call item' do
    action  = :show
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_search_call
    url_opt = { id: item.id }
    @readers.each do |user|
      able  = can?(user, action, SearchCall)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = search_call_url(**url_opt, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt)
      end
    end
  end

end
