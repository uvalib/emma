# test/controllers/periodical_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class PeriodicalControllerTest < ActionDispatch::IntegrationTest

  MODEL         = Periodical
  CONTROLLER    = :periodical
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER, expect: :success }.freeze

  TEST_USERS    = %i[anonymous emmadso].freeze
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = %i[anonymous].freeze # TODO: periodical write tests

  READ_FORMATS  = :all
  WRITE_FORMATS = :all

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
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      u_opt = options
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'periodical show - details of an existing periodical' do
    action  = :show
    series  = sample_periodical.seriesId
    params  = PARAMS.merge(action: action, id: series)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      u_opt = options
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] = XML_FAILURE if fmt == :xml
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'periodical new - add metadata for a new periodical' do
    action  = :new
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'periodical create - a new periodical' do
    action  = :create
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        post_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'periodical edit - metadata for an existing periodical' do
    action  = :edit
    series  = sample_periodical.seriesId
    params  = PARAMS.merge(action: action, id: series)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'periodical update - modify an existing periodical' do
    action  = :update
    series  = sample_periodical.seriesId
    params  = PARAMS.merge(action: action, id: series)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        put_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'periodical destroy - remove an existing periodical' do
    action  = :destroy
    series  = sample_periodical.seriesId
    params  = PARAMS.merge(action: action, id: series)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        delete_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

end
