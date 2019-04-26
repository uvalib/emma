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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /api
  # The main API test page.
  #
  def index
    ApiService.instance(false).callback_url = request.base_url
  end

end

__loading_end(__FILE__)
