# app/controllers/api_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiController
#
# @see ApiHelper
# @see app/views/api
#
class ApiController < ApplicationController

  include ApiConcern
  include UserConcern
  include ParamsConcern
  include SessionConcern
  include SerializationConcern

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

  public

  # == GET /api
  # The main API test page.
  #
  def index
    @api_results = ApiTesting.run_trials(user: current_user)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /api/v2/API_PATH[?API_OPTIONS]
  # == GET /api/v2/API_PATH[?user=API_USER]
  # Direct access to the API guarded by authentication.  If the session is
  # authenticated the endpoint will be (implicitly) contacted as that user.
  # A configured user (one with a fixed OAuth2 token) may be specified in the
  # URL options with "?user=xxx@bookshare.org" (or simply "?user=xxx" and
  # "@bookshare.org" will be appended).
  #
  # NOTE: Intended to translate URLs within data directly into actionable links
  #
  def v2
    __debug { "API #{__method__} | params = #{params.inspect}" }
    opt  = url_parameters
    path = opt.delete(:api_path)
    if (user = opt.delete(:user)).present?
      user = user.downcase
      user = "#{user}@bookshare.org" unless user.include?('@')
      path = request.fullpath.sub(/\?.*/, '')
      path << '?' << opt.to_param if opt.present?
      redirect_to sign_in_as_path(id: user, redirect: path)
    else
      # noinspection RubyYardParamTypeMatch
      @api_result = api_method(request.method, path, opt)
      respond_to do |format|
        format.html
        format.json { render_json show_values }
        format.xml  { render_xml  show_values }
      end
    end
  end

  # == GET /api/image[?url=...]
  # Get an image.
  #
  # @see app/assets/javascripts/feature/image.js
  #
  # == Usage Notes
  # This provides JavaScript with a way of asynchronously getting images
  # without having to contend with CSRF.
  #
  def image
    response   = Faraday.get(params[:url]) # TODO: caching
    image_data = Base64.encode64(response.body)
    mime_type  = response.headers['content-type']
    render plain: image_data, format: mime_type, layout: false
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Hash, nil] items
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(items = @api_results)
    result =
      items.map { |action, response|
        response = try_json_parse(response)
        if response.is_a?(Hash)
          response =
            response.map { |k, v|
              # noinspection RubyCaseWithoutElseBlockInspection
              case k
                when :parameters then v = v.to_s.sub(/^\((.*)\)$/, '\1')
                when :status     then v = v.presence&.upcase || 'MISSING'
                when :error      then v = try_exception_parse(v)
              end
              [k, v]
            }.to_h
          response.delete(:value) if response[:error].present?
        end
        [action, response]
      }.to_h
    { bookshare_api: result }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Hash, nil] item
  # @param [Symbol]    as             Unused.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @api_result, as: nil)
    result =
      item.map { |k, v|
        v = try_json_parse(v) if %i[result exception].include?(k)
        [k, v]
      }.to_h
    { bookshare_api: result }
  end

end

__loading_end(__FILE__)
