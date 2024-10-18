# test/controllers/data_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class DataControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER    = :data
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER }.freeze

  TEST_USERS    = ALL_TEST_USERS
  TEST_READERS  = TEST_USERS

  READ_FORMATS  = :all

  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'data index' do
    read_test(:index, meth: __method__)
  end

  test 'data show orgs table' do
    read_test(:show, meth: __method__, id: :orgs)
  end

  test 'data submissions' do
    read_test(:submissions, meth: __method__, anonymous: true)
  end

  test 'data field counts' do
    read_test(:counts, meth: __method__, anonymous: true)
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # Perform a DataController test for #TEST_READERS in all #TEST_FORMATS to
  # verify expected response status.
  #
  # @param [Symbol]  action
  # @param [Boolean] anonymous        Does not require authentication.
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def read_test(action, anonymous: nil, meth: nil, **opt)
    meth  ||= __method__
    params  = PARAMS.merge(action: action, **opt)
    options = OPTIONS.merge(action: action, test: meth, expect: :success)

    @readers.each do |user|
      able  = anonymous || user&.administrator?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
