# test/controllers/sys_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SysControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER    = :sys
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER, expect: :success }.freeze

  TEST_USERS    = ALL_TEST_USERS
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = TEST_USERS

  READ_FORMATS  = :html
  WRITE_FORMATS = :html

  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'system - list pages' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'system - disk_space' do
    action  = :disk_space
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'system - environment' do
    action  = :environment
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'system - headers' do
    action  = :headers
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'system - internals' do
    action  = :internals
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'system - loggers' do
    action  = :loggers
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'system - settings' do
    action  = :settings
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'system - database' do
    action  = :database
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] = (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
