# test/controllers/category_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class CategoryControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER    = 'category'
  OPTIONS       = { controller: CONTROLLER }.freeze

  TEST_USERS    = [ANONYMOUS, EMMA_COLLECTION].freeze
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = [ANONYMOUS].freeze # TODO: category write tests

  TEST_CATEGORY = 'Animals'

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'category index - list all categories' do
    endpoint = category_index_path
    options  = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

=begin
  test 'category show - details of an existing category' do
    endpoint = category_path(id: TEST_CATEGORY)
    options  = OPTIONS.merge(test: __method__, action: 'show')
    options[:expect] = :success
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end
=end

=begin
  test 'category new - add metadata for a new category' do
    endpoint = new_category_path
    options  = OPTIONS.merge(test: __method__, action: 'new')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end
=end

=begin
  test 'category create - a new category' do
    endpoint = category_index_path
    options  = OPTIONS.merge(test: __method__, action: 'create')
    TEST_WRITERS.each do |user|
      post_as(user, endpoint, options)
    end
  end
=end

=begin
  test 'category edit - metadata for an existing category' do
    endpoint = edit_category_path(id: TEST_CATEGORY)
    options  = OPTIONS.merge(test: __method__, action: 'edit')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end
=end

=begin
  test 'category update - modify an existing category' do
    endpoint = category_path(id: TEST_CATEGORY)
    options  = OPTIONS.merge(test: __method__, action: 'update')
    TEST_WRITERS.each do |user|
      put_as(user, endpoint, options)
    end
  end
=end

=begin
  test 'category destroy - remove an existing category' do
    endpoint = category_path(id: TEST_CATEGORY)
    options  = OPTIONS.merge(test: __method__, action: 'destroy')
    TEST_WRITERS.each do |user|
      delete_as(user, endpoint, options)
    end
  end
=end

end
