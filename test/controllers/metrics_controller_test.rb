# test/controllers/metrics_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'
require 'prometheus/middleware/exporter'

class MetricsControllerTest < ActionDispatch::IntegrationTest

  OPTIONS = {}.freeze

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

=begin # NOTE: This doesn't work because '/metrics' is handled within Rack.
  test 'metrics' do
    opt = OPTIONS.merge(format: :text)
    url = '/metrics'
    run_test(__method__) do
      get(url, as: :text)
      assert_result :success, **opt
    end
  end
=end

  test 'test metrics' do
    opt = OPTIONS.merge(format: :json)
    url = metrics_test_url
    url = "#{url}.json" if opt[:json]
    run_test(__method__) do
      get(url)
      assert_result(:success, **opt)
    end
  end

end
