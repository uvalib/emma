# test/controllers/sys_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class SysControllerTest < ApplicationControllerTestCase

  CTRLR = :sys
  PRM   = { controller: CTRLR }.freeze
  OPT   = { controller: CTRLR, sign_out: false }.freeze

  TEST_READERS  = ALL_TEST_USERS
  TEST_WRITERS  = ALL_TEST_USERS

  READ_FORMATS  = :html
  WRITE_FORMATS = :html

  NO_READ       = formats_other_than(*READ_FORMATS).freeze
  NO_WRITE      = formats_other_than(*WRITE_FORMATS).freeze

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

  # Perform a SysController test for #TEST_READERS in all #TEST_FORMATS to
  # verify expected response status.
  #
  # @param [Symbol]  action
  # @param [Boolean] redirect         Will always redirect.
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def read_test(action, redirect: nil, meth: nil, **opt)
    meth  ||= __method__
    params  = PRM.merge(action: action, **opt)
    options = OPT.merge(action: action, test: meth)
    options[:expect] = :success unless redirect

    @readers.each do |user|
      able  = user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          if able && redirect
            opt[:expect] = :redirect
            opt[:format] = :any
          else
            opt[:expect] = :not_found if able
          end
        end
        get_as(user, url, **opt)
      end
    end
  end

end
