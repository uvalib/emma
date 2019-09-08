# test/system/health_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

# NOTE: These are not really appropriate for Capybara because they're JSON.
class HealthTest < ApplicationSystemTestCase

  test 'health - visit version' do
    run_test(__method__) do
      visit version_path
      assert_text 'version'
    end
  end

  test 'health - visit health check' do
    run_test(__method__) do
      visit healthcheck_path
      assert_text 'healthy'
    end
  end

end
