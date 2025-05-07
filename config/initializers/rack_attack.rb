# config/initializers/rack_attack.rb

require 'rack/attack'

BLOCKED_RANGES = [
  '15.177.0.0' # 2025-05-07 *.us-west-2.compute.amazonaws.com
].freeze

BLOCKED_RANGES.each do |range|
  case range
    when /\.0\.0\.0$/ then range += '/8'
    when /\.0\.0$/    then range += '/16'
    when /\.0$/       then range += '/24'
  end
  Rack::Attack.blocklist_ip(range)
end

# Using 503 because it may make attacker think that they have successfully
# DOSed the site. Rack::Attack returns 403 for blocklists by default.
Rack::Attack.blocklisted_responder = lambda do |_request|
  [ 503, {}, ['Blocked']]
end
