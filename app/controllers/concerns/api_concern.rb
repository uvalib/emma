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
  # :section:
  # ===========================================================================

  public

  # Fill @item and @pref with account information and preferences.
  #
  # @param [String] id                If *nil*, assumes the current user.
  #
  # @return [Array<(ApiMyAccountSummary, ApiMyAccountPreferences)>]
  # @return [Array<(nil,nil)>] If there was a problem.
  #
  def fetch_my_account(id: nil)
    api   = ApiService.instance
    error = nil
    if id && (item = api.get_account(user: id)).error?
      error = item.error_message
    elsif !id && (item = api.get_my_account).error?
      error = item.error_message
    elsif (pref = api.get_my_preferences).error?
      error = pref.error_message
    end
    if error
      flash.clear
      flash[:alert] = error
      item = pref = nil
    end
    return item, pref
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
