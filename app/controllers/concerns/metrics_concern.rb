# app/controllers/concerns/metrics_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'prometheus/client'

# MetricsConcern
#
module MetricsConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'MetricsConcern')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Prometheus metrics registry.
  #
  # @type [Prometheus::Client::Registry]
  #
  REGISTRY = Prometheus::Client.registry

  # Set up one or more metrics of the same type.
  #
  # @param [Symbol]                     type
  # @param [Hash{Symbol=>String|Array}] hash
  #
  # @return [Hash{Symbol=>Prometheus::Client::Metric}]
  #
  def self.metrics(type, hash)
    hash.map { |name, docstring|
      if REGISTRY.exist?(name)
        Log.warn { "#{name}: metric already registered" }
      else
        [name, REGISTRY.send(type, name, *docstring)]
      end
    }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Prometheus counter metrics.
  #
  # @type [Hash{Symbol=>Prometheus::Client::Counter}]
  #
  # @see https://github.com/prometheus/client_ruby#counter
  #
  # noinspection RubyConstantNamingConvention
  Counter = metrics(:counter, {
    test_recv: 'Data acquisition requests',   # TODO: testing - remove
    test_send: 'Data modification requests',  # TODO: testing - remove
    # TODO: counter metrics...
  })

  # Prometheus gauge metrics.
  #
  # @type [Hash{Symbol=>Prometheus::Client::Gauge}]
  #
  # @see https://github.com/prometheus/client_ruby#gauge
  #
  # noinspection RubyConstantNamingConvention
  Gauge = metrics(:gauge, {
    test_gauge:  'A simple gauge that rands between 1 and 100 inclusive', # TODO: testing - remove
    test_gauge2: 'A second gauge', # TODO: testing - remove
    # TODO: gauge metrics...
  })

  # Prometheus histogram metrics.
  #
  # @type [Hash{Symbol=>Prometheus::Client::Histogram}]
  #
  # @see https://github.com/prometheus/client_ruby#histogram
  #
  # noinspection RubyConstantNamingConvention
  Histogram = metrics(:histogram, {
    test_histogram: 'A histogram example', # TODO: testing - remove
    # TODO: histogram metrics...
  })

  # Prometheus summary metrics.
  #
  # @type [Hash{Symbol=>Prometheus::Client::Summary}]
  #
  # @see https://github.com/prometheus/client_ruby#summary
  #
  # noinspection RubyConstantNamingConvention
  Summary = metrics(:summary, {
    test_summary: 'A summary example', # TODO: testing - remove
    # TODO: summary metrics...
  })

end

__loading_end(__FILE__)
