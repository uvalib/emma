# test/system/home_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class HomeTest < ApplicationSystemTestCase

  test 'home - visit main page' do
    run_test(__method__) do
      visit home_url
      assert_selector 'h1', text: 'Welcome to EMMA'
    end
  end

  test 'home - visit welcome page' do
    run_test(__method__) do
      visit welcome_url
      assert_selector 'h1', text: 'Welcome to EMMA'
    end
  end

  test 'home - visit dashboard page' do
    run_test(__method__) do
      visit dashboard_url
      assert_flash alert: AUTH_FAILURE
    end
  end

end
