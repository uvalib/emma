# app/controllers/tool_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/tool" pages.
#
# @see file:app/views/tool/**
#
class ToolController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include SerializationConcern
  include ToolConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include AbstractController::Callbacks
    # :nocov:
  end

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user

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

  # == GET /tool
  #
  # Index of tool pages.
  #
  # @see #tool_index_path             Route helper
  #
  def index
  end

  # ===========================================================================
  # :section: Math Detective API
  # ===========================================================================

  public

  # == GET /tool/md
  #
  # A simple Math Detective API test page for selecting a single file.
  #
  # @see #md_trial_path               Route helper
  #
  def md
  end

  # == GET  /tool/md_proxy
  # == POST /tool/md_proxy
  #
  # Proxy the Math Detective API request to avoid CORS.
  #
  # @see #md_proxy_path               Route helper
  #
  def md_proxy
    meth     = request.request_method
    meth     = ActionDispatch::Request::HTTP_METHOD_LOOKUP[meth]
    prm      = url_parameters
    url      = "#{ENV['MD_BASE_PATH']}/#{prm.delete(:path)}"
    key      = request.headers['X-API-Key'] || ENV['MD_API_KEY']
    headers  = { 'X-API-Key' => key, 'Content-Type' => 'application/json' }
    response = Faraday.send(meth, url, prm.to_json, headers)
    render json: safe_json_parse(response.body), status: response.status
  end

end

__loading_end(__FILE__)
