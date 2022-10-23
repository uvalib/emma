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
# @see AccountDecorator
# @see AccountsDecorator
# @see file:app/views/account/**
#
class AccountController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
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

  protected

  # Database results for :index.
  #
  # @return [Array<User>, nil]
  #
  attr_reader :list

  # Database results for :show.
  #
  # @return [User, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /account
  #
  # List all user accounts.
  #
  # @see #users_path                  Route helper
  # @see #account_index_path          Route helper
  # @see AccountConcern#get_accounts
  #
  def index
    __debug_route
    prm    = paginator.initial_parameters
    search = prm.delete(:like)
    prm.except!(:limit, *Paginator::PAGINATION_KEYS)
    @list  = get_accounts(*search, **prm).to_a
    paginator.finalize(@list, **prm)
  end

  # == GET /account/show/:id
  #
  # Display details of an existing user account.
  #
  # @see #show_account_path           Route helper
  # @see AccountConcern#get_account
  #
  def show
    __debug_route
    @item = get_account
  end

  # == GET /account/new
  #
  # Display a form for creation of a new user account.
  #
  # @see #new_account_path            Route helper
  # @see AccountConcern#new_account
  #
  def new
    __debug_route
    @item = new_account
  end

  # == POST  /account/create
  # == PUT   /account/create
  # == PATCH /account/create
  #
  # Create a new user account.
  #
  # == Usage Notes
  # In order to allow the database to auto-generate the record ID, the :id
  # parameter will be rejected unless "force_id=true" is included in the URL
  # parameters.
  #
  # @see #create_account_path         Route helper
  # @see AccountConcern#create_account
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def create
    __debug_route
    @item   = create_account(no_raise: true)
    success = @item.errors.blank?
    respond_to do |format|
      if success
        format.html { redirect_success(__method__) }
        format.json { render :show, location: @item, status: :created }
      else
        # @type [ActiveModel::Errors]
        errors = @item.errors
        format.html { redirect_failure(__method__, error: errors) }
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  end

  # == GET /account/edit/:id
  # == GET /account/edit/SELECT
  # == GET /account/edit_select
  #
  # Display a form for modification of an existing user account.
  #
  # @see #edit_account_path           Route helper
  # @see #edit_select_account_path    Route helper
  # @see #show_menu?
  # @see AccountConcern#get_account
  #
  def edit
    __debug_route
    @item = nil
    unless show_menu?((ids = id_params))
      @item  = get_account((selected = ids.shift))
      errors = []
      errors << "Record #{quote(selected)} not found" if @item.blank? # TODO: I18n
      errors << "Ignored extra id(s): #{quote(ids)}"  if ids.present? # TODO: I18n
      flash_now_alert(*errors) if errors.present?
    end
  end

  # == PUT   /account/update/:id
  # == PATCH /account/update/:id
  #
  # Update an existing user account.
  #
  # @see #update_account_path         Route helper
  # @see AccountConcern#update_account
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def update
    __debug_route
    __debug_request
    @item   = update_account(no_raise: true)
    success = @item && @item.errors.blank?
    respond_to do |format|
      if success
        format.html { redirect_success(__method__) }
        format.json { render :show, location: @item, status: :ok }
      else
        # @type [ActiveModel::Errors, String]
        errors = @item&.errors || "#{params[:id]} not found" # TODO: I18n
        format.html { redirect_failure(__method__, error: errors) }
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  end

  # == GET /account/delete/:id
  # == GET /account/delete/SELECT
  # == GET /account/delete_select
  #
  # Select existing user account(s) to remove.
  #
  # If :id is "SELECT" then a menu of deletable items is presented.
  #
  # @see #delete_account_path         Route helper
  # @see #delete_select_account_path  Route helper
  # @see #show_menu?
  # @see AccountConcern#find_accounts
  #
  def delete
    __debug_route
    @list = nil
    unless show_menu?((ids = id_params))
      @list = find_accounts(ids)
      unless @list.present? || last_operation_path&.include?('/destroy')
        flash_now_alert("No records match #{quote(ids)}") # TODO: I18n
      end
    end
  end

  # == DELETE /account/destroy/:id
  #
  # Remove existing user account(s).
  #
  # @see #destroy_account_path        Route helper
  # @see AccountConcern#destroy_accounts
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def destroy
    __debug_route
    @list = destroy_accounts
    respond_to do |format|
      format.html { redirect_success(__method__) }
      format.json { head :no_content }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether URL parameters require that a menu should be shown rather
  # than operating on an explicit set of identifiers.
  #
  # @param [Array<String,Integer>] ids  Default: `#id_params`.
  #
  def show_menu?(ids = nil)
    ids ||= id_params
    ids.blank? || ids.include?('SELECT')
  end

end

__loading_end(__FILE__)
