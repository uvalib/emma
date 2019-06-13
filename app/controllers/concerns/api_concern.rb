# app/controllers/concerns/api_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiConcern
#
module ApiConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'ApiConcern')
  end

  include ApiHelper

  # Log API request times.
  if Log.info?
    extend TimeHelper
    ActiveSupport::Notifications.subscribe('request.faraday') do |*args|
      _name    = args.shift # 'request.faraday'
      starts   = args.shift
      ends     = args.shift
      _payload = args.shift
      env      = args.shift
      method   = env[:method].to_s.upcase
      url      = env[:url]
      host     = url.host
      uri      = url.request_uri
      duration = time_span(starts.to_f, ends.to_f)
      Log.info { '[%s] %s %s (%s)' % [host, method, uri, duration] }
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Initialize API service.
  #
  # @return [void]
  #
  def initialize_service
    @api = ApiService.update(user: current_user)
  end

end

__loading_end(__FILE__)
