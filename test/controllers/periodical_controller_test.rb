# test/controllers/periodical_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class PeriodicalControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :periodical
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = %i[anonymous].freeze # TODO: periodical write tests

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

  test 'periodical index - list all periodicals' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = periodical_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end
  end

  test 'periodical show - details of an existing periodical' do
    action  = :show
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    item    = sample_periodical
    url_opt = { id: item.seriesId }
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = periodical_url(**url_opt, format: fmt)
        opt = options.merge(format: fmt)
        opt[:expect] = XML_FAILURE if fmt == :xml
        get_as(user, url, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'periodical new - add metadata for a new periodical' do
    action  = :new
    options = OPTIONS.merge(action: action, test: __method__)
    url     = new_periodical_url
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'periodical create - a new periodical' do
    action  = :create
    options = OPTIONS.merge(action: action, test: __method__)
    url     = periodical_index_url
    @writers.each do |user|
      post_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'periodical edit - metadata for an existing periodical' do
    action  = :edit
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_periodical
    url_opt = { id: item.seriesId }
    url     = edit_periodical_url(**url_opt)
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'periodical update - modify an existing periodical' do
    action  = :update
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_periodical
    url_opt = { id: item.seriesId }
    url     = periodical_url(**url_opt)
    @writers.each do |user|
      put_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'periodical destroy - remove an existing periodical' do
    action  = :destroy
    options = OPTIONS.merge(action: action, test: __method__)
    item    = sample_periodical
    url_opt = { id: item.seriesId }
    url     = periodical_url(**url_opt)
    @writers.each do |user|
      delete_as(user, url, **options)
    end if allowed_format(only: :html)
  end

end
