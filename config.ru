# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

# =============================================================================
# Blocked IP addresses
# =============================================================================

require 'rack/attack'
require_relative 'config/initializers/rack_attack'

use Rack::Attack

# =============================================================================
# Prometheus metrics
# =============================================================================

require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

use Rack::Deflater
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

run ->(*) { [200, { 'Content-Type' => 'text/html' }, %w[OK]] }

# =============================================================================
# Start application
# =============================================================================

run Rails.application
Rails.application.load_server
