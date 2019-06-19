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

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

=begin # TODO: authenticate_user ???
  before_action :authenticate_user!
=end
  before_action :update_user, except: %i[image]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :initialize_service, except: %i[image]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /api
  # The main API test page.
  #
  def index
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
  def v2 # TODO: testing - remove
    __debug { "API #{__method__} | params = #{params.inspect}" }
    @opt  = url_parameters.except(:format)
    @path = @opt.delete(:api_path)
    if (user = @opt.delete(:user)).present?
      user = user.downcase
      user = "#{user}@bookshare.org" unless user.include?('@')
      path = request.fullpath.sub(/\?.*/, '')
      path << '?' << @opt.to_param if @opt.present?
      redirect_to sign_in_as_path(id: user, redirect: path)
    else
      respond_to do |format|
        format.html
        format.json { render json: api_method(request.method, @path, @opt) }
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

end

__loading_end(__FILE__)
