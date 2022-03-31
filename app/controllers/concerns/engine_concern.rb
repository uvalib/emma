# app/controllers/concerns/engine_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for dynamic specification of service endpoints.
#
module EngineConcern

  extend ActiveSupport::Concern

  include ParamsHelper

  include FlashConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The service identified by the given value.
  #
  # @param [String, Symbol, Class<ApiService>] service
  #
  # @return [String]
  #
  def service_name(service)
    # noinspection RailsParamDefResolve
    service.try(:service_name) || ApiService.name_for(service)
  end

  # The session key associated with the given service.
  #
  # @param [String, Symbol, Class<ApiService>] service
  #
  # @return [String]
  #
  def service_session_key(service)
    service = service_name(service)
    "app.#{service}.engine"
  end

  # The URL of the user-selected service engine.
  #
  # @param [String, Symbol, Class<ApiService>] service
  #
  # @return [String, nil]             If different than the default engine.
  #
  def requested_engine(service)
    from_session = get_session_engine(service) or return
    url = service.engine_url(from_session)
    url unless url == service.default_engine_url
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Recall the user-selected service engine name or endpoint.
  #
  # @param [String, Symbol, Class<ApiService>] service
  #
  # @return [String, nil]
  #
  def get_session_engine(service)
    key = service_session_key(service)
    session[key].presence
  end

  # Remember (or forget) the user-selected service engine name or endpoint.
  #
  # @param [String, Symbol, Class<ApiService>] service
  # @param [String, nil]                       new_value
  #
  # @return [String, nil]
  #
  def set_session_engine(service, new_value)
    key = service_session_key(service)
    if new_value.present?
      session[key] = new_value.to_s
    else
      session.delete(key) && nil
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  RESET_KEYS = ApiService::RESET_KEYS

  # Process the URL parameter for setting the endpoint for the given service.
  #
  # The engine may be specified by deployment, e.g. "&engine=staging", or by
  # URL (if that URL matches or derives from a `service.engines` value).
  # If this resolves to the default engine then session['app.*.engine'] is
  # deleted; otherwise it will be set to a key of `service.engines` or to an
  # explicit URL if necessary.
  #
  # If no (valid) :engine parameter was supplied, this method evaluates the
  # current value of session['app.*.engine'], and will delete it if appropriate
  # (but without redirecting).
  #
  # @param [Class<ApiService>] service
  #
  # @return [Any, nil]                *nil* if not redirecting
  #
  def set_engine_callback(service)
    opt = request_parameters
    val = url = nil
    if (in_params = opt.key?(:engine)) && (val = opt.delete(:engine).presence)
      if RESET_KEYS.include?(val.strip.downcase.to_sym)
        val = nil
      elsif (key = service.engine_key(val))
        val = key
      elsif (url = service.engine_url(val))
        val = nil
      else
        val = nil
        Log.warn("#{__method__}: invalid engine #{val.inspect}")
      end
    elsif !in_params && (current = get_session_engine(service))
      if current.include?('/')
        url = current
      else
        val = current
      end
    end
    val = nil if val && (val == service.default_engine_key)
    url = nil if url && (url == service.default_engine_url)
    if set_session_engine(service, (val || url))
      engine_url = url || service.engine_url(val)
      flash_reset_notice(service, engine_url)
    end
    redirect_to opt if in_params
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  FLASH_RESET_NOTICE_SPACES = 3

  # Display a flash notice indicating that a service has been overridden.
  #
  # @param [String, Symbol, Class<ApiService>] service
  # @param [String] url               Current service URL endpoint.
  # @param [Hash]   opt               Passed to #flash_now_notice except:
  #
  # @option opt [Integer, String] :spaces
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def flash_reset_notice(service, url, **opt)
    service = service_name(service)
    engine  = "#{service} engine"
    notice  = ERB::Util.h("#{engine.upcase} #{url.inspect}")
    spaces  = opt.delete(:spaces) || FLASH_RESET_NOTICE_SPACES
    spaces  = HTML_SPACE * spaces if spaces.is_a?(Integer)
    spaces  = ERB::Util.h(spaces)
    label   = '[RESTORE DEFAULT]' # TODO: I18n
    tip     = "Click to restore the default #{engine}" # TODO: I18n
    link    = { engine: 'reset' }
    link    = flash_link(label, link, title: tip)
    flash_now_notice((notice << spaces << link), **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
