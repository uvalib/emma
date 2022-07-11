# test/system/health_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

# NOTE: These are not really appropriate for Capybara because they're JSON.
class HealthTest < ApplicationSystemTestCase

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'health - visit version' do
    url = version_url
    run_test(__method__) do
      visit url
      assert_text 'version'
    end
  end

  test 'health - visit health check' do
    url = healthcheck_url
    run_test(__method__) do
      visit url
      assert_text 'healthy'
    end
  end

end
