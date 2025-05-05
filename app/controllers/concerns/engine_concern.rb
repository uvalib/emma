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

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include ActionController::Redirecting
  end
  # :nocov:

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
  # @return [String, nil]             If different from the default engine.
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
  # @return [any]
  # @return [nil]                     If not redirecting
  #
  def set_engine_callback(service)
    val = url = nil
    opt = request_parameters
    if (in_params = opt.key?(:engine))
      if (val = opt.delete(:engine)).blank?
        val = nil
      elsif ApiService::RESET_KEYS.include?(val.strip.downcase.to_sym)
        val = nil
      elsif (key = service.engine_key(val))
        val = key
      elsif (url = service.engine_url(val))
        val = nil
      else
        Log.warn("#{__method__}: invalid engine #{val.inspect}")
        val = nil
      end
    elsif (current = get_session_engine(service))&.include?('/')
      url = current
    elsif current
      val = current
    end
    val = nil if val && (val == service.default_engine_key)
    url = nil if url && (url == service.default_engine_url)
    set_session_engine(service, (val || url))
    redirect_to opt if in_params
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    base.helper(THIS_MODULE) if base.respond_to?(:helper)
  end

end

__loading_end(__FILE__)
