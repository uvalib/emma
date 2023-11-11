# test/controllers/tool_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ToolControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER    = :tool
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

  test 'tool - index' do
    read_test(:index, meth: __method__, anonymous: true)
  end

  test 'tool - Math Detective' do
    read_test(:md, meth: __method__)
  end

  test 'tool - bibliographic lookup' do
    read_test(:lookup, meth: __method__)
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # read_test
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
      able  = anonymous || user&.present?
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
