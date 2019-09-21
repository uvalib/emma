# test/controllers/periodical_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class PeriodicalControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'periodical'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_COLLECTION].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = [ANONYMOUS].freeze # TODO: periodical write tests

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'periodical index - list all periodicals' do
    options = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = periodical_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  test 'periodical show - details of an existing periodical' do
    periodical = sample_periodical.seriesId
    options    = OPTIONS.merge(test: __method__, action: 'show')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = periodical_url(id: periodical, format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  if TESTING_HTML

    test 'periodical new - add metadata for a new periodical' do
      url = new_periodical_url
      opt = OPTIONS.merge(test: __method__, action: 'new')
      TEST_WRITERS.each do |user|
        get_as(user, url, opt)
      end
    end

    test 'periodical create - a new periodical' do
      url = periodical_index_url
      opt = OPTIONS.merge(test: __method__, action: 'create')
      TEST_WRITERS.each do |user|
        post_as(user, url, opt)
      end
    end

    test 'periodical edit - metadata for an existing periodical' do
      periodical = sample_periodical.seriesId
      url        = edit_periodical_url(id: periodical)
      opt        = OPTIONS.merge(test: __method__, action: 'edit')
      TEST_WRITERS.each do |user|
        get_as(user, url, opt)
      end
    end

    test 'periodical update - modify an existing periodical' do
      periodical = sample_periodical.seriesId
      url        = periodical_url(id: periodical)
      opt        = OPTIONS.merge(test: __method__, action: 'update')
      TEST_WRITERS.each do |user|
        put_as(user, url, opt)
      end
    end

    test 'periodical destroy - remove an existing periodical' do
      periodical = sample_periodical.seriesId
      url        = periodical_url(id: periodical)
      opt        = OPTIONS.merge(test: __method__, action: 'destroy')
      TEST_WRITERS.each do |user|
        delete_as(user, url, opt)
      end
    end

  end

end
