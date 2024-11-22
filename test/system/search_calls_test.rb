# test/system/search_calls_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class SearchCallsTest < ApplicationSystemTestCase

  CTRLR = :search_call
  PRM   = { controller: CTRLR }.freeze

  setup do
    @dev = find_user(:test_dev)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search_calls - index' do
    user      = @dev
    action    = :index
    params    = PRM.merge(action: action)

    start_url = url_for(**params)
    final_url = start_url

    run_test(__method__) do

      # Not available anonymously.
      visit start_url
      assert_flash(alert: AUTH_FAILURE)
      sign_in_as(user)

      # Successful sign-in should redirect back.
      show_url
      screenshot
      assert_current_url(final_url)

      # The listing should be the first of one or more results pages.
      assert_valid_index_page(CTRLR, page: 0)

    end
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'search_calls system test coverage' do
    # Endpoints covered by controller tests:
    skipped = %i[show]
    check_system_coverage SearchCallController, except: skipped
  end

end
