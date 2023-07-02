# app/controllers/data_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class DataController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include DataConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_admin!, except: %i[submissions counts]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /data[?tables=...]
  #
  # Get the contents of all database tables (or the named tables if given).
  # (Defaults to HTML output.)
  #
  # @see #data_index_path             Route helper
  #
  def index
    __log_activity
    __debug_route
    default_format(:html)
    @list = get_tables
    respond_to(request.format)
  end

  # === GET /data/TABLE_NAME
  #
  # Get the contents of the indicated database table.
  #
  # @see #data_path                   Route helper
  #
  def show
    __log_activity
    __debug_route
    default_format(:html)
    @name, @item = get_table_records
    respond_to(request.format)
  end

  # === GET /data/submissions
  #
  # Get a listing of EMMA submissions.
  #
  # @see #data_submissions_path       Route helper
  #
  def submissions
    __log_activity
    __debug_route
    default_format(:json)
    @name, @list = get_submission_records
    respond_to(request.format)
  end

  # === GET /data/counts
  #
  # Get a listing of EMMA submission field values.
  #
  # @see #data_counts_path            Route helper
  #
  def counts
    __log_activity
    __debug_route
    @list = get_submission_field_counts(all: true?(params[:all]))
    respond_to(request.format)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Because DataHelper is biased toward assuming that non-HTML is expected,
  # defaulting to HTML format requires setting `params[:format]` to make it
  # appear as though a format has been explicitly requested.
  #
  # @param [Symbol, String] fmt
  #
  # @return [void]
  #
  def default_format(fmt)
    unless params[:format]
      params[:format] = fmt.to_s
      request.format  = fmt.to_sym
    end
  end

end

__loading_end(__FILE__)
