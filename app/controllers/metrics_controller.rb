# app/controllers/metrics_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# MetricsController
#
# NOTE: "GET /metrics" is handled by Prometheus::Middleware::Exporter
#
class MetricsController < ApplicationController

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /metrics/test
  # A temporary endpoint to test various Prometheus metrics.
  #
  # * A *counter* is a metric for a quantity that accumulates a numerical
  #   value.
  #
  # * A *gauge* is a metric that represents a single numerical value that can
  #   go up and down arbitrarily.
  #
  # * A *histogram* aggregates accumulations of values in "buckets" which
  #   divide a number space into mutually exclusive regions.
  #
  # * A *summary* is a metric...
  #
  def test
    value = rand(0..100)

    Counter[:test_recv].increment({ service: 'GET' },  3 * value)
    Counter[:test_send].increment({ service: 'POST' }, 2 * value)

    Gauge[:test_gauge].set({ route: :gauge }, value)
    Gauge[:test_gauge2].set({}, value)
    g =
      REGISTRY.get(:test_gauge3) ||
      REGISTRY.gauge(:test_gauge3, 'A third gauge')
    g.set({ bb: 'second label' }, 18)

    Histogram[:test_histogram].observe({}, value / 16)
    Histogram[:test_histogram].observe({}, value / 4)
    Histogram[:test_histogram].observe({}, value)
    Histogram[:test_histogram].observe({}, value * 4)
    Histogram[:test_histogram].observe({}, value * 16)

    Summary[:test_summary].observe({}, value)

    respond_to do |format|
      format.any do
        render json: { message: 'Success' }, status: :ok
      end
    end
  end

end

__loading_end(__FILE__)