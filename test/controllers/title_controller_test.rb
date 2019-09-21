# test/controllers/title_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class TitleControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'title'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_COLLECTION].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = [ANONYMOUS].freeze # TODO: catalog title write tests

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'title index - list all titles' do
    options = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = title_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  test 'title show - details of an existing title' do
    title   = sample_title.bookshareId
    options = OPTIONS.merge(test: __method__, action: 'show')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = title_url(id: title, format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  if TESTING_HTML

    test 'title new - add metadata for a new title' do
      url     = new_title_url
      options = OPTIONS.merge(test: __method__, action: 'new')
      TEST_WRITERS.each do |user|
        get_as(user, url, options)
      end
    end

    test 'title create - a new title' do
      url     = title_index_url
      options = OPTIONS.merge(test: __method__, action: 'create')
      TEST_WRITERS.each do |user|
        post_as(user, url, options)
      end
    end

    test 'title edit - metadata for an existing title' do
      title   = sample_title.bookshareId
      url     = edit_title_url(id: title)
      options = OPTIONS.merge(test: __method__, action: 'edit')
      TEST_WRITERS.each do |user|
        get_as(user, url, options)
      end
    end

    test 'title update - modify an existing title' do
      title   = sample_title.bookshareId
      url     = title_url(id: title)
      options = OPTIONS.merge(test: __method__, action: 'update')
      TEST_WRITERS.each do |user|
        put_as(user, url, options)
      end
    end

    test 'title destroy - remove an existing title' do
      title   = sample_title.bookshareId
      url     = title_url(id: title)
      options = OPTIONS.merge(test: __method__, action: 'destroy')
      TEST_WRITERS.each do |user|
        delete_as(user, url, options)
      end
    end

  end

end
