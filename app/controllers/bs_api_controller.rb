# app/controllers/bs_api_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "Bookshare API Explorer" ("/bs_api" page) requests.
#
# @see BsApiConcern
# @see file:app/views/bs_api/**
#
class BsApiController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include SerializationConcern
  include BsApiConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include AbstractController::Callbacks
    # :nocov:
  end

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user, except: %i[image]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /bs_api
  #
  # The main API test page.
  #
  def index
    return unless permitted_session
    __log_activity(anonymous: true)
    __debug_route
    @api_results = ApiTesting.run_trials(user: current_user)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /bs_api/v2/API_PATH[?API_OPTIONS]
  # == GET /bs_api/v2/API_PATH[?user=API_USER]
  #
  # Direct access to the API guarded by authentication.  If the session is
  # authenticated the endpoint will be (implicitly) contacted as that user.
  # A configured user (one with a fixed OAuth2 token) may be specified in the
  # URL options with "?user=xxx@bookshare.org" (or simply "?user=xxx" and
  # "@bookshare.org" will be appended).
  #
  # NOTE: Intended to translate URLs within data directly into actionable links
  #
  def v2
    prm  = url_parameters
    user = prm.delete(:user).presence
    return unless user || permitted_session
    __log_activity(anonymous: true)
    __debug_route
    if user
      path = request.fullpath.sub(/\?.*/, '')
      path << '?' << url_query(prm) if prm.present?
      # noinspection RubyMismatchedArgumentType
      redirect_to sign_in_as_path(id: bookshare_user(user), redirect: path)
    else
      path = prm.delete(:api_path).to_s
      @api_result = bs_api_explorer(request.method, path, **prm)
      respond_to do |format|
        format.html
        format.json { render_json show_values }
        format.xml  { render_xml  show_values }
      end
    end
  end

  # == GET /bs_api/image[?url=...]
  #
  # Get an image.
  #
  # @see file:app/assets/javascripts/feature/images.js
  #
  # == Usage Notes
  # This provides JavaScript with a way of asynchronously getting images
  # without having to contend with CSRF.
  #
  def image
    #__log_activity
    # __debug_route
    response   = Faraday.get(params[:url]) # TODO: caching
    image_data = Base64.encode64(response.body)
    mime_type  = response.headers['content-type']
    render plain: image_data, format: mime_type, layout: false
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Respond with JSON and status 401 unless being called from an authorized
  # session.
  #
  # == URL parameters
  #
  # * fail=true     Causes the method to always returns *false*.
  # * no_test=true  Causes normal checks to proceed in the 'test' environment
  #                   (otherwise the method always returns *true*).
  #
  # @return [Boolean]
  #
  def permitted_session
    unless true?(params[:fail])
      return true if Rails.env.test? && !true?(params[:no_test])
      return true if current_user.present? || dev_client?
    end
    render json: { error: 'Unauthorized' }, status: :unauthorized
    false
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Hash] items
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(items = @api_results, **opt)
    opt.reverse_merge!(wrap: :bookshare_api)
    result =
      items.map { |action, response|
        response = safe_json_parse(response)
        if response.is_a?(Hash)
          response =
            response.map { |k, v|
              # noinspection RubyCaseWithoutElseBlockInspection
              case k
                when :parameters then v = v.to_s.sub(/^\((.*)\)$/, '\1')
                when :status     then v = v.presence&.upcase || 'MISSING'
                when :error      then v = safe_exception_parse(v)
              end
              [k, v]
            }.to_h
          response.delete(:value) if response[:error].present?
        end
        [action, response]
      }.to_h
    super(result, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Hash] item
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def show_values(item = @api_result, **opt)
    opt.reverse_merge!(name: :bookshare_api)
    result =
      item.map { |k, v|
        v = safe_json_parse(v) if %i[result exception].include?(k)
        [k, v]
      }.to_h
    super(result, **opt)
  end

end

__loading_end(__FILE__)
