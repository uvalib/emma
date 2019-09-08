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
  # :section:
  # ===========================================================================

  test 'reading_list index - list all reading lists' do
    endpoint = reading_list_index_path
    options  = OPTIONS.merge(test: __method__, action: 'index')
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'reading_list show - details of an existing reading list' do
    reading_list = sample_reading_list.readingListId
    endpoint     = reading_list_path(id: reading_list)
    options      = OPTIONS.merge(test: __method__, action: 'show')
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'reading_list new - add metadata for a new reading list' do
    endpoint = new_reading_list_path
    options  = OPTIONS.merge(test: __method__, action: 'new')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'reading_list create - a new reading list' do
    endpoint = reading_list_index_path
    options  = OPTIONS.merge(test: __method__, action: 'create')
    TEST_WRITERS.each do |user|
      post_as(user, endpoint, options)
    end
  end

  test 'reading_list edit - metadata for an existing reading list' do
    reading_list = sample_reading_list.readingListId
    endpoint     = edit_reading_list_path(id: reading_list)
    options      = OPTIONS.merge(test: __method__, action: 'edit')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'reading_list update - modify an existing reading list' do
    reading_list = sample_reading_list.readingListId
    endpoint     = reading_list_path(id: reading_list)
    options      = OPTIONS.merge(test: __method__, action: 'update')
    TEST_WRITERS.each do |user|
      put_as(user, endpoint, options)
    end
  end

  test 'reading_list destroy - remove an existing reading list' do
    reading_list = sample_reading_list.readingListId
    endpoint     = reading_list_path(id: reading_list)
    options      = OPTIONS.merge(test: __method__, action: 'destroy')
    TEST_WRITERS.each do |user|
      delete_as(user, endpoint, options)
    end
  end

end
