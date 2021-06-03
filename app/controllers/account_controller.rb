# app/controllers/account_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Manage user accounts as represented in the User table ("/account" pages).
#
# Note that these are not directly related to Bookshare accounts -- only to the
# "reflections" of those accounts maintained in the local database.
#
class AccountController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include AccountConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource :user

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /account
  #
  # List all user accounts.
  #
  def index
    __debug_route
    opt    = pagination_setup
    search = opt.delete(:like)
    opt.except!(:limit, *PAGINATION_KEYS) # TODO: paginate account listings
    # noinspection RubyYardParamTypeMatch
    @list  = get_accounts(search, **opt)
  end

  # == GET /account/show/:id
  #
  # Display details of an existing user account.
  #
  def show
    __debug_route
    @item = User.find(params[:id])
  end

  # == GET /account/new
  #
  # Display a form for creation of a new user account.
  #
  def new
    __debug_route
    @item = User.new
  end

  # == POST  /account/create
  # == PUT   /account/create
  # == PATCH /account/create
  #
  # Create a new user account.
  #
  def create
    __debug_route
    @item   = User.new(user_params)
    success = @item.save
    respond_to do |format|
      if success
        format.html { redirect_success(__method__) }
        format.json { render :show, location: @item, status: :created }
      else
        format.html { redirect_failure(__method__, error: @item.errors) }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # == GET /account/edit/:id
  # == GET /account/edit/SELECT
  # == GET /account/edit_select
  #
  # Display a form for modification of an existing user account.
  #
  def edit
    __debug_route
    selected = (id_list.first unless show_menu?)
    @item = (User.find(selected) if selected.present?)
  end

  # == PUT   /account/update/:id
  # == PATCH /account/update/:id
  #
  # Update an existing user account.
  #
  def update
    __debug_route
    __debug_request
    @item   = User.find(params[:id])
    success = @item.update(user_params)
    respond_to do |format|
      if success
        format.html { redirect_success(__method__) }
        format.json { render :show, location: @item, status: :ok }
      else
        format.html { redirect_failure(__method__, error: @item.errors) }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # == GET /account/delete/:id
  # == GET /account/delete/SELECT
  # == GET /account/delete_select
  #
  # Remove an existing user account.
  #
  # If :id is "SELECT" then a menu of deletable items is presented.
  #
  def delete
    __debug_route
    @list = (id_list.presence unless show_menu?)
    @list = @list && User.find(@list) || []
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # == DELETE /account/destroy/:id
  #
  # Remove an existing user account.
  #
  def destroy
    __debug_route
    @item = User.find(params[:id])
    @item.destroy
    respond_to do |format|
      format.html { redirect_success(__method__) }
      format.json { head :no_content }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether URL parameters indicate that a menu should be shown rather
  # than operating on an explicit set of identifiers.
  #
  # @param [String, Array<String>, nil] id_params  Default: `params[:id]`.
  #
  def show_menu?(id_params = nil)
    id_params ||= params[:selected] || params[:id]
    Array.wrap(id_params).include?('SELECT')
  end

  # Interpret the identifier parameter as one or more comma-delimited spans of
  # database IDs.
  #
  # @param [String, Array<String>, nil] id_params  Default: `params[:id]`.
  #
  # @return [Array<Integer>]
  #
  def id_list(id_params = nil)
    id_params ||= params[:selected] || params[:id]
    Array.wrap(id_params).flat_map { |part|
      if part.is_a?(String)
        part = part.strip
        part = part.split(/\s*,\s*/) if part.include?(',')
      end
      part
    }.map { |part| part.to_i if digits_only?(part) }.compact
  end

end

__loading_end(__FILE__)
