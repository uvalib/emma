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

  include ApiHelper

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :update_user
  #before_action :authenticate_user! # TODO: testing - restore
  before_action :authenticate_user!, except: %i[v2] # TODO: testing - remove :v2
  before_action :initialize_service

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
    __debug "API #{__method__} | params = #{params.inspect}"
    @opt  = params.to_unsafe_h
    @opt  = @opt.except(:controller, :action, :format).symbolize_keys
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

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Update the current user with previously-acquired authentication data.
  #
  # @return [void]
  #
  def update_user
    auth_data = session['omniauth.auth']
    warden    = request.env['warden']
    warden.set_user(User.from_omniauth(auth_data)) if warden && auth_data
  end

  # Initialize API service.
  #
  # @return [void]
  #
  def initialize_service
    ApiService.update(user: current_user)
  end

end

__loading_end(__FILE__)
