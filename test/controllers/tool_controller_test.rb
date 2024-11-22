# test/controllers/tool_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class ToolControllerTest < ApplicationControllerTestCase

  CTRLR = :tool
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

  # Perform a ToolController test for #TEST_READERS in all #TEST_FORMATS to
  # verify expected response status.
  #
  # @param [Symbol]  action
  # @param [Boolean] anonymous        Does not require authentication.
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def read_test(action, anonymous: false, meth: nil, **opt)
    meth  ||= __method__
    params  = PRM.merge(action: action, **opt)
    options = OPT.merge(action: action, test: meth, expect: :success)

    @readers.each do |user|
      able  = anonymous || user&.present?
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          opt[:expect] = :not_found if able
        end
        get_as(user, url, **opt)
      end
    end
  end

end
