# test/controllers/search_call_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class SearchCallControllerTest < ActionDispatch::IntegrationTest

  MODEL        = SearchCall
  CONTROLLER   = :search_call
  PARAMS       = { controller: CONTROLLER }.freeze
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [*CORE_TEST_USERS, :test_dev].uniq.freeze
  TEST_READERS = TEST_USERS

  READ_FORMATS = :all

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

  # Perform a SearchCallController test for #TEST_READERS in all #TEST_FORMATS.
  #
  # @param [Symbol]  action
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def read_test(action, meth: nil, **opt)
    meth  ||= __method__
    params  = PARAMS.merge(action: action, **opt)
    options = OPTIONS.merge(action: action, test: meth, expect: :success)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
