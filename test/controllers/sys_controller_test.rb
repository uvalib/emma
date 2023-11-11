# test/controllers/sys_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SysControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER    = :sys
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER }.freeze

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
    read_test(:index, meth: __method__)
  end

  test 'system - disk_space' do
    read_test(:disk_space, meth: __method__)
  end

  test 'system - environment' do
    read_test(:environment, meth: __method__)
  end

  test 'system - headers' do
    read_test(:headers, meth: __method__)
  end

  test 'system - internals' do
    read_test(:internals, meth: __method__)
  end

  test 'system - loggers' do
    read_test(:loggers, meth: __method__)
  end

  test 'system - settings' do
    read_test(:settings, meth: __method__)
  end

  test 'system - database' do
    read_test(:database, meth: __method__, redirect: true )
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # read_test
  #
  # @param [Symbol]  action
  # @param [Boolean] redirect         Will always redirect.
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def read_test(action, meth: nil, redirect: nil, **opt)
    meth  ||= __method__
    params  = PARAMS.merge(action: action, **opt)
    options = OPTIONS.merge(action: action, test: meth)
    options[:expect] = :success unless redirect

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
