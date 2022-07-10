# test/controllers/title_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class TitleControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :title
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = %i[anonymous].freeze # TODO: catalog title write tests

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'title index - list all titles' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = title_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end
  end

  test 'title show - details of an existing title' do
    action  = :show
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    item    = sample_title
    url_opt = { id: item.bookshareId }
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = title_url(**url_opt, format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'title new - add metadata for a new title' do
    action  = :new
    options = OPTIONS.merge(action: action, test: __method__)
    url     = new_title_url
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'title create - a new title' do
    action  = :create
    options = OPTIONS.merge(action: action, test: __method__)
    url     = title_index_url
    @writers.each do |user|
      post_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'title edit - metadata for an existing title' do
    action  = :edit
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_title
    url_opt = { id: item.bookshareId }
    url     = edit_title_url(**url_opt)
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'title update - modify an existing title' do
    action  = :update
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_title
    url_opt = { id: item.bookshareId }
    url     = title_url(**url_opt)
    @writers.each do |user|
      put_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'title destroy - remove an existing title' do
    action  = :destroy
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_title
    url_opt = { id: item.bookshareId }
    url     = title_url(**url_opt)
    @writers.each do |user|
      delete_as(user, url, **options)
    end if allowed_format(only: :html)
  end

end
