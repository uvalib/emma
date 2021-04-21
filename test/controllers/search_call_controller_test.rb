# test/controllers/search_call_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchCallControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'search_call'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_DSO].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = [].freeze # Not relevant for this controller.

  TEST_FORMATS = %i[html] # TODO: remove - testing

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search call index - no search' do
    options = OPTIONS.merge(test: __method__, action: 'index')
    TEST_READERS.each do |user|
      able  = can?(user, :list, SearchCall)
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
        get_as(user, url, opt)
      end
    end
  end

  test 'search call index - sample search' do
    search  = sample_search_call
    options = OPTIONS.merge(test: __method__, action: 'index')
    TEST_READERS.each do |user|
      able  = can?(user, :list, SearchCall)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = search_call_index_url(search_call: search, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, opt)
      end
    end
  end

  test 'search call show - details search call item' do
    item    = sample_search_result.repositoryRecordId
    options = OPTIONS.merge(test: __method__, action: 'show')
    TEST_READERS.each do |user|
      able  = can?(user, :read, SearchCall)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = search_call_url(id: item, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, opt)
      end
    end
  end

end
