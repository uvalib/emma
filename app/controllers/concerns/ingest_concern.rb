# app/controllers/concerns/ingest_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

# Controller support methods for access to the Ingest API service.
#
module IngestConcern

  extend ActiveSupport::Concern

  include ApiConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the EMMA Federated Ingest API service.
  #
  # @return [IngestService]
  #
  def ingest_api
    if (engine = requested_ingest_engine)
      IngestService.new(base_url: engine)
    else
      # noinspection RubyMismatchedReturnType
      api_service(IngestService)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL of the user-selected ingest engine.
  #
  # @return [String, nil]             If different than the default engine.
  #
  def requested_ingest_engine
    url = IngestService.engine_url(get_session_ingest_engine)
    url unless url == IngestService.default_engine_url
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of the `session` entry for overriding the default ingest engine.
  #
  # @type [String]
  #
  INGEST_ENGINE_SESSION_KEY = 'app.ingest.engine'

  # @type [String, nil]
  def get_session_ingest_engine
    session[INGEST_ENGINE_SESSION_KEY].presence
  end

  # @type [String, nil]
  def set_session_ingest_engine(new_value)
    if new_value.present?
      session[INGEST_ENGINE_SESSION_KEY] = new_value.to_s
    else
      clear_session_ingest_engine && nil
    end
  end

  # @type [String, nil]
  def clear_session_ingest_engine
    session.delete(INGEST_ENGINE_SESSION_KEY)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Process the URL parameter for setting the ingest engine URL.
  #
  # The engine may be specified by deployment, e.g. "&engine=staging", or by
  # URL (if that URL matches or derives from a #INGEST_ENGINES value).  If this
  # resolves to the default ingest engine then session['app.ingest.engine'] is
  # deleted; otherwise it will be set to a key of #INGEST_ENGINES or to an
  # explicit URL if necessary.
  #
  # If no (valid) :engine parameter was supplied, this method evaluates the
  # current value of session['app.ingest.engine'], and will delete it if
  # appropriate (but without redirecting).
  #
  def set_ingest_engine
    opt = request_parameters
    val = url = nil
    if (in_params = opt.key?(:engine)) && (val = opt.delete(:engine).presence)
      if ApiService::RESET_KEYS.include?(val.strip.downcase.to_sym)
        val = nil
      elsif (key = IngestService.engine_key(val))
        val = key
      elsif (url = IngestService.engine_url(val))
        val = nil
      else
        val = nil
        Log.warn("#{__method__}: invalid engine #{val.inspect}")
      end
    elsif !in_params && (current = get_session_ingest_engine)
      if current.include?('/')
        url = current
      else
        val = current
      end
    end
    val = nil if val && (val == IngestService.default_engine_key)
    url = nil if url && (url == IngestService.default_engine_url)
    if set_session_ingest_engine(val || url)
      url   ||= IngestService.engine_url(val)
      restore = make_path(request.fullpath, engine: 'reset')
      restore = %Q(<a href="#{restore}">[RESTORE DEFAULT]</a>).html_safe
      notice  = ERB::Util.h("INGEST ENGINE #{url.inspect}  ") << restore
      #flash_now_notice(notice, html: true) # TODO: ExecReport html_safe
      flash.now[:notice] = [*flash.now[:notice], notice]
    end
    redirect_to opt if in_params
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
