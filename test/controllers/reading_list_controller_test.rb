# test/controllers/reading_list_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ReadingListControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'reading_list'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_DSO, EMMA_COLLECTION].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = [ANONYMOUS].freeze # TODO: reading list write tests

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'reading_list index - list all reading lists' do
    options = OPTIONS.merge(test: __method__, action: 'index')
    TEST_READERS.each do |user|
      able  = can?(user, :list, ReadingList)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = reading_list_index_url(format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, opt)
      end
    end
  end

  test 'reading_list show - details of an existing reading list' do
    reading_list = sample_reading_list.readingListId
    options      = OPTIONS.merge(test: __method__, action: 'show')
    TEST_READERS.each do |user|
      able  = can?(user, :read, ReadingList)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = reading_list_url(id: reading_list, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  if TESTING_HTML

    test 'reading_list new - add metadata for a new reading list' do
      url     = new_reading_list_url
      options = OPTIONS.merge(test: __method__, action: 'new')
      TEST_WRITERS.each do |user|
        get_as(user, url, options)
      end
    end

    test 'reading_list create - a new reading list' do
      url     = reading_list_index_url
      options = OPTIONS.merge(test: __method__, action: 'create')
      TEST_WRITERS.each do |user|
        post_as(user, url, options)
      end
    end

    test 'reading_list edit - metadata for an existing reading list' do
      reading_list = sample_reading_list.readingListId
      url          = edit_reading_list_url(id: reading_list)
      options      = OPTIONS.merge(test: __method__, action: 'edit')
      TEST_WRITERS.each do |user|
        get_as(user, url, options)
      end
    end

    test 'reading_list update - modify an existing reading list' do
      reading_list = sample_reading_list.readingListId
      url          = reading_list_url(id: reading_list)
      options      = OPTIONS.merge(test: __method__, action: 'update')
      TEST_WRITERS.each do |user|
        put_as(user, url, options)
      end
    end

    test 'reading_list destroy - remove an existing reading list' do
      reading_list = sample_reading_list.readingListId
      url          = reading_list_url(id: reading_list)
      options      = OPTIONS.merge(test: __method__, action: 'destroy')
      TEST_WRITERS.each do |user|
        delete_as(user, url, options)
      end
    end

  end

end
