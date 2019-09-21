# test/controllers/metrics_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'
require 'prometheus/middleware/exporter'

class MetricsControllerTest < ActionDispatch::IntegrationTest

  OPTIONS      = {}.freeze

  TEST_USERS   = [ANONYMOUS].freeze
  TEST_READERS = TEST_USERS

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

=begin # NOTE: This doesn't work because '/metrics' is handled within Rack.
  test 'metrics' do
    url = '/metrics'
    opt = OPTIONS.merge(format: :text)
    run_test(__method__) do
      get url, as: :text
      assert_result :success, opt
    end
  end
=end

  test 'test metrics' do
    url = metrics_test_url
    opt = OPTIONS.merge(format: :json)
    run_test(__method__) do
      get url, as: :json
      assert_result :success, opt
    end
  end

end
