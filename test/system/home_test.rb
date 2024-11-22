# test/system/home_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class HomeTest < ApplicationSystemTestCase

  CTRLR = :home
  PRM   = { controller: CTRLR }.freeze
  TITLE = page_title(**PRM, action: :welcome).freeze

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'home - main page (anonymous)' do
    url = home_url
    run_test(__method__) do
      visit url
      screenshot
      assert_valid_page(heading: TITLE)
    end
  end

  test 'home - welcome page (anonymous)' do
    url = welcome_url
    run_test(__method__) do
      visit url
      screenshot
      assert_valid_page(heading: TITLE)
    end
  end

  test 'home - dashboard page (anonymous)' do
    url = dashboard_url
    run_test(__method__) do
      visit url
      screenshot
      assert_flash(alert: AUTH_FAILURE)
    end
  end

end
