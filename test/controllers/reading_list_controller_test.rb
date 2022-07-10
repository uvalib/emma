# test/controllers/reading_list_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ReadingListControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :reading_list
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = %i[anonymous].freeze # TODO: reading list write tests

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  # On-going problems with XML serialization...
  XML_FAILURE = :internal_server_error

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'reading_list index - list all reading lists' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, ReadingList)
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
        get_as(user, url, **opt)
      end
    end
  end

  test 'reading_list show - details of an existing reading list' do
    action  = :show
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_reading_list
    url_opt = { id: item.readingListId }
    @readers.each do |user|
      able  = can?(user, action, ReadingList)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = reading_list_url(**url_opt, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        opt[:expect] = XML_FAILURE if (fmt == :xml) && user.is_a?(User)
        get_as(user, url, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'reading_list new - add metadata for a new reading list' do
    action  = :new
    options = OPTIONS.merge(action: action, test: __method__)
    url     = new_reading_list_url
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'reading_list create - a new reading list' do
    action  = :create
    options = OPTIONS.merge(action: action, test: __method__)
    url     = reading_list_index_url
    @writers.each do |user|
      post_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'reading_list edit - metadata for an existing reading list' do
    action  = :edit
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_reading_list
    url_opt = { id: item.readingListId }
    url     = edit_reading_list_url(**url_opt)
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'reading_list update - modify an existing reading list' do
    action  = :update
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_reading_list
    url_opt = { id: item.readingListId }
    url     = reading_list_url(**url_opt)
    @writers.each do |user|
      put_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'reading_list destroy - remove an existing reading list' do
    action  = :destroy
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_reading_list
    url_opt = { id: item.readingListId }
    url     = reading_list_url(**url_opt)
    @writers.each do |user|
      delete_as(user, url, **options)
    end if allowed_format(only: :html)
  end

end
