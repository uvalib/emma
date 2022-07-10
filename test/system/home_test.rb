# test/system/home_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class HomeTest < ApplicationSystemTestCase

  INDEX_TITLE = 'Welcome to EMMA'

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'home - visit main page' do
    url = home_url
    run_test(__method__) do
      visit url
      assert_valid_page heading: INDEX_TITLE
      success_screenshot
    end
  end

  test 'home - visit welcome page' do
    url = welcome_url
    run_test(__method__) do
      visit url
      assert_valid_page heading: INDEX_TITLE
      success_screenshot
    end
  end

  test 'home - visit dashboard page' do
    url = dashboard_url
    run_test(__method__) do
      visit url
      assert_flash alert: AUTH_FAILURE
      success_screenshot
    end
  end

end
