# test/system/metrics_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class MetricsTest < ApplicationSystemTestCase

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'metrics - index - visit metrics' do
    url = '/metrics'
    run_test(__method__) do
      visit url
      assert_text 'TYPE http_server_requests_total counter'
    end unless not_applicable("'/metrics' is handled within Rack")
  end

  test 'metrics - test - visit test metrics' do
    url = metrics_test_url
    run_test(__method__) do
      visit url
      assert_response :success
      assert_text '{"message":"Success"}'
    end unless not_applicable('Capybara can only deal with HTML results')
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'metrics system test coverage' do
    skipped = []
    check_system_coverage MetricsController, except: skipped
  end

end
