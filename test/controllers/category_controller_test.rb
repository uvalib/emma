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
  # :section: Read tests
  # ===========================================================================

  test 'category index - list all categories' do
    options = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = category_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

=begin # TODO: show single category test
  test 'category show - details of an existing category' do
    options = OPTIONS.merge(test: __method__, action: 'show')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = category_url(id: TEST_CATEGORY, format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end
=end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  if TESTING_HTML

=begin # TODO: category new test ???
    test 'category new - add metadata for a new category' do
      url     = new_category_url
      options = OPTIONS.merge(test: __method__, action: 'new')
      TEST_WRITERS.each do |user|
        get_as(user, url, options)
      end
    end
=end

=begin # TODO: category create test ???
    test 'category create - a new category' do
      url     = category_index_url
      options = OPTIONS.merge(test: __method__, action: 'create')
      TEST_WRITERS.each do |user|
        post_as(user, url, options)
      end
    end
=end

=begin # TODO: category edit test ???
    test 'category edit - metadata for an existing category' do
      url     = edit_category_url(id: TEST_CATEGORY)
      options = OPTIONS.merge(test: __method__, action: 'edit')
      TEST_WRITERS.each do |user|
        get_as(user, url, options)
      end
    end
=end

=begin # TODO: category update test ???
    test 'category update - modify an existing category' do
      url     = category_url(id: TEST_CATEGORY)
      options = OPTIONS.merge(test: __method__, action: 'update')
      TEST_WRITERS.each do |user|
        put_as(user, url, options)
      end
    end
=end

=begin # TODO: category destroy test ???
    test 'category destroy - remove an existing category' do
      url     = category_url(id: TEST_CATEGORY)
      options = OPTIONS.merge(test: __method__, action: 'destroy')
      TEST_WRITERS.each do |user|
        delete_as(user, url, options)
      end
    end
=end

  end

end
