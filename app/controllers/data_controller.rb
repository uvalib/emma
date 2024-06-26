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

  ANON_OPS = %i[submissions counts].freeze

  before_action :update_user
  before_action :authenticate_admin!, except: ANON_OPS

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /data[?tables=...]
  #
  # Get the contents of all database tables (or the named tables if given).
  # (Defaults to HTML output.)
  #
  # @see #data_index_path             Route helper
  # @see DataConcern#get_tables
  #
  def index
    __log_activity
    __debug_route
    default_format(:html)
    tables = data_params[:tables]
    @names = tables&.include?(:all) ? table_names : tables
    @list  = get_tables(*@names) if @names
    respond_to(request.format)
  end

  # === GET /data/TABLE_NAME
  #
  # Get the contents of the indicated database table.
  #
  # @see #data_path                   Route helper
  # @see DataConcern#get_table_records
  #
  def show
    __log_activity
    __debug_route
    default_format(:html)
    # noinspection RubyMismatchedArgumentType
    table = params[:id] ? array_param(params[:id]) : data_params[:tables]
    return redirect_to action: :index                if table.nil?
    return redirect_to action: :index, tables: table if table.many?
    # noinspection RubyMismatchedVariableType
    @name = table.first
    @item = get_table_records(@name)
    respond_to(request.format)
  end

  # === GET /data/submissions
  #
  # Get a listing of EMMA submissions.
  #
  # @see #data_submissions_path               Route helper
  # @see DataConcern#get_submission_records
  #
  def submissions
    __log_activity
    __debug_route
    default_format(:json) unless Rails.env.test?
    @item = get_submission_records(@name)
    respond_to(request.format)
  end

  # === GET /data/counts
  #
  # Get a listing of EMMA submission field values.
  #
  # @see #data_counts_path                        Route helper
  # @see DataConcern#get_submission_field_counts
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
