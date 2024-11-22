# test/controllers/search_call_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class SearchCallControllerTest < ApplicationControllerTestCase

  MODEL = SearchCall
  CTRLR = :search_call
  PRM   = { controller: CTRLR }.freeze
  OPT   = { controller: CTRLR, sign_out: false }.freeze

  TEST_READERS = [*CORE_TEST_USERS, :test_dev].uniq.freeze

  READ_FORMATS = :all

  NO_READ      = formats_other_than(*READ_FORMATS).freeze

  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search call index - no search' do
    read_test(:index, meth: __method__)
  end

  test 'search call index - sample search' do
    read_test(:index, meth: __method__, search_call: search_calls(:example))
  end

  test 'search call show - details search call item' do
    read_test(:show, meth: __method__, id: search_calls(:example).id)
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # Perform a SearchCallController test for #TEST_READERS in all #TEST_FORMATS
  # to verify expected response status.
  #
  # @param [Symbol]  action
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def read_test(action, meth: nil, **opt)
    meth  ||= __method__
    params  = PRM.merge(action: action, **opt)
    options = OPT.merge(action: action, test: meth, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
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
