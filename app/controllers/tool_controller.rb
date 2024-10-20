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
  include ToolConcern

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include AbstractController::Callbacks
  end
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!, except: :index

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :md_auth,     only:  %i[md md_proxy]
  before_action :lookup_auth, only:  %i[lookup get_job_result]

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /tool
  #
  # Index of tool pages.
  #
  # @see #tool_index_path             Route helper
  #
  def index
    __log_activity(anonymous: true)
    __debug_route
  end

  # ===========================================================================
  # :section: Routes - Math Detective API
  # ===========================================================================

  public

  # === GET /tool/md
  #
  # A simple Math Detective API test page for selecting a single file.
  #
  # @see #md_trial_path               Route helper
  #
  def md
    __log_activity
    __debug_route
  end

  # === GET  /tool/md_proxy
  # === POST /tool/md_proxy
  #
  # Proxy the Math Detective API request to avoid CORS.
  #
  # @see #md_proxy_path               Route helper
  #
  def md_proxy
    __log_activity
    __debug_route
    __debug_request unless request.get?
    meth     = request.request_method
    meth     = ActionDispatch::Request::HTTP_METHOD_LOOKUP[meth]
    prm      = url_parameters
    url      = make_path(ENV_VAR['MD_BASE_PATH'], prm.delete(:path))
    key      = request.headers['X-API-Key'] || ENV_VAR['MD_API_KEY']
    headers  = { 'X-API-Key' => key, 'Content-Type' => 'application/json' }
    response = Faraday.send(meth, url, prm.to_json, headers)
    render json: safe_json_parse(response.body), status: response.status
  end

  # ===========================================================================
  # :section: Routes - Identifier Lookup
  # ===========================================================================

  public

  # === GET /tool/lookup
  #
  # Lookup bibliographic information.
  #
  def lookup
    __log_activity
    __debug_route
  end

  # === GET /tool/get_job_result/:job_id[?column=(output|diagnostic|error)]
  # === GET /tool/get_job_result/:job_id/*path[?column=(output|diagnostic|error)]
  #
  # Return a value from the 'job_results' table, where :job_id is the value for
  # the matching :active_job_id.
  #
  def get_job_result
    render json: LookupJob.job_result(**normalize_hash(params))
  end

end

__loading_end(__FILE__)
