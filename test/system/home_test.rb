# test/system/home_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class HomeTest < ApplicationSystemTestCase

  CONTROLLER  = :home

  INDEX_TITLE = page_title(controller: CONTROLLER, action: :welcome).freeze

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'home - main page (anonymous)' do
    url = home_url
    run_test(__method__) do
      visit url
      assert_valid_page(heading: INDEX_TITLE)
      screenshot
    end
  end

  test 'home - welcome page (anonymous)' do
    url = welcome_url
    run_test(__method__) do
      visit url
      assert_valid_page(heading: INDEX_TITLE)
      screenshot
    end
  end

  test 'home - dashboard page (anonymous)' do
    url = dashboard_url
    run_test(__method__) do
      visit url
      assert_flash(alert: AUTH_FAILURE)
      screenshot
    end
  end

end
