# test/controllers/search_call_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchCallControllerTest < ActionDispatch::IntegrationTest

  MODEL        = SearchCall
  CONTROLLER   = :search_call
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER, expect: :success }.freeze

  TEST_USERS   = %i[anonymous test_dso test_dev].freeze
  TEST_READERS = TEST_USERS

  READ_FORMATS = :all

  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search call index - no search' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'search call index - sample search' do
    action  = :index
    item    = sample_search_call
    params  = PARAMS.merge(action: action, search_call: item)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'search call show - details search call item' do
    action  = :show
    item    = sample_search_call
    params  = PARAMS.merge(action: action, id: item.id)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
