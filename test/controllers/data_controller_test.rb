# test/controllers/data_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class DataControllerTest < ApplicationControllerTestCase

  CTRLR = :data
  PRM   = { controller: CTRLR }.freeze
  OPT   = { controller: CTRLR, sign_out: false }.freeze

  TEST_READERS = ALL_TEST_USERS

  READ_FORMATS = :all

  NO_READ      = formats_other_than(*READ_FORMATS).freeze

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
  def read_test(action, anonymous: false, meth: nil, **opt)
    meth  ||= __method__
    params  = PRM.merge(action: action, **opt)
    options = OPT.merge(action: action, test: meth, expect: :success)

    @readers.each do |user|
      able  = anonymous || user&.administrator?
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
