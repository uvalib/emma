# app/helpers/layout_helper/status.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Control bar which indicates and controls selection of non-standard search
# and ingest engines.
#
module LayoutHelper::Status

  include LayoutHelper::Common

  include LinkHelper
  include ParamsHelper

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include EngineConcern
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A structure for the result of #engine_status.
  #
  # @!attribute [r] service
  #   The subclass of ApiService.
  #   @return [Class]
  #
  # @!attribute [r] url
  #   The non-default service endpoint.
  #   @return [String, nil]
  #
  # @!attribute [r] key
  #   The non-default :engine parameter value ("production", "staging", "qa").
  #   @return [String, nil]
  #
  # @!attribute fix
  #   A non-default :engine parameter value ("production", "staging", "qa").
  #   @return [String, nil]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  EngineStatus = Struct.new(:service, :url, :key, :fix)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show engine controls.
  #
  # @param [Hash, nil] p              Default: `#request_parameters`.
  #
  def show_engine_controls?(p = nil)
    p ||= request_parameters
    %i[search upload manifest].include?(p[:controller]&.to_sym)
  end

  # render_engine_controls
  #
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to the container.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def render_engine_controls(css: '.engine-controls', **opt)
    search = engine_status(SearchService)
    ingest = engine_status(IngestService)
    case
      when search[:key] then ingest[:fix] = search[:key] unless ingest[:key]
      when ingest[:key] then search[:fix] = ingest[:key] unless search[:key]
      else                   return # Neither service has been overridden.
    end
    prepend_css!(opt, css)
    html_div(**opt) do
      engine_control(search) << engine_control(ingest)
    end
  end

  # engine_status
  #
  # @param [Class<ApiService>] service
  #
  # @return [EngineStatus]
  #
  def engine_status(service)
    url = requested_engine(service)
    key = url && get_session_engine(service)
    EngineStatus.new(service, url, key, nil)
  end

  # engine_control
  #
  # @param [EngineStatus] engine
  # @param [String]       css       Characteristic CSS class/selector.
  # @param [Hash]         opt       Passed to the container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def engine_control(engine, css: '.engine-control', **opt)
    service, url, _key, fix = engine.values

    label  = service.name || 'unknown'
    label  = html_span(label, class: 'service')

    data   = url || service.default_engine_url
    value  = url || 'default'
    value  = html_span(value, class: 'endpoint', 'data-url': data)

    c_lbl  = fix ? 'UPDATE' : 'RESTORE'
    c_opt  = { class: "control #{c_lbl.underscore}" }
    c_opt[:title] = 'Click to set to the matching value' if fix
    if (service == SearchService) && (params[:controller] != 'search')
      c_prm = { controller: 'search', action: 'index' }
    elsif (service == IngestService) && (params[:controller] == 'search')
      c_prm = { controller: 'upload', action: 'index' }
    else
      c_prm = request_parameters
    end
    c_link = url_for(c_prm.merge(engine: fix || 'reset'))
    ctrl   = link_to("[#{c_lbl}]", c_link, c_opt)

    name   = label.underscore.delete_suffix('_service')
    status = url ? 'changed' : 'default'
    fix  &&= 'fix'
    prepend_css!(opt, css, name, status, fix)
    html_div(**opt) do
      label << value << ctrl
    end
  end

end

__loading_end(__FILE__)
