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

  ##before_action :authenticate_user! # TODO: testing - restore
  #before_action :authenticate_user!, except: :bypass # TODO: testing - remove
  before_action :authenticate_user!, except: %i[bypass v2] # TODO: testing - remove :v2

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /api
  # The main API test page.
  #
  def index
  end

  # == GET /api/bypass
  # The main API test page by-passing authentication.
  #
  def bypass # TODO: testing - remove
    render 'api/index'
  end

  # == GET /api/v2
  # Direct access to the API guarded by authentication.
  #
  # NOTE: Intended to translate URLs within data directly into actionable links
  #
  def v2 # TODO: testing - remove
    __debug "API #{__method__} | params = #{params.inspect}"
    @opt  = params.to_unsafe_h
    @opt  = @opt.except(:controller, :action, :format).symbolize_keys
    @path = @opt.delete(:api_path)
    respond_to do |format|
      format.html
      format.json { render json: api_method(request.method, @path, @opt) }
    end
  end

end

__loading_end(__FILE__)
