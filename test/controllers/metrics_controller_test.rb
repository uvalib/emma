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
  # :section:
  # ===========================================================================

=begin
  # NOTE: This doesn't work because '/metrics' is handled within Rack.
  test 'metrics' do
    run_test(__method__) do
      get '/metrics', as: :text
      assert_result :success, OPTIONS.merge(media_type: :text)
    end
  end
=end

  test 'test metrics' do
    run_test(__method__) do
      get metrics_test_path, as: :json
      assert_result :success, OPTIONS.merge(media_type: :json)
    end
  end

end
