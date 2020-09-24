# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

# =============================================================================
# Prometheus metrics
# =============================================================================

require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

use Rack::Deflater
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

run ->(*) { [200, { 'Content-Type' => 'text/html' }, %w(OK)] }

# =============================================================================
# Start application
# =============================================================================

run Rails.application
