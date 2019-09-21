# test/system/metrics_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class MetricsTest < ApplicationSystemTestCase

=begin # NOTE: This doesn't work because '/metrics' is handled within Rack.
  test 'metrics - visit metrics' do
    run_test(__method__) do
      visit '/metrics'
      assert_text 'TYPE http_server_requests_total counter'
    end
  end
=end

=begin # NOTE: Doesn't work because Capybara can only deal with HTML results.
  test 'metrics - visit test metrics' do
    run_test(__method__) do
      visit metrics_test_url
      assert_response :success
      assert_text '{"message":"Success"}'
    end
  end
=end

end
