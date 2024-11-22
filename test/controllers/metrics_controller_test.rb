# test/controllers/metrics_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'
require 'prometheus/middleware/exporter'

class MetricsControllerTest < ApplicationControllerTestCase

  PRM = {}.freeze
  OPT = {}.freeze

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

=begin # NOTE: This doesn't work because '/metrics' is handled within Rack.
  test 'metrics' do
    opt = OPT.merge(format: :text)
    url = '/metrics'
    url = make_path(url, **PRM) if PRM.present?
    run_test(__method__) do
      get(url, as: :text)
      assert_result :success, **opt
    end
  end
=end

  test 'metrics test' do
    opt = OPT.merge(format: :json)
    url = metrics_test_url(**PRM)
    url = "#{url}.json" if opt[:json]
    run_test(__method__) do
      get(url)
      assert_result(:success, **opt)
    end
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'metrics controller test coverage' do
    # Endpoints covered by system tests:
    skipped = %i[
      index
    ]
    check_controller_coverage MetricsController, except: skipped
  end

end
