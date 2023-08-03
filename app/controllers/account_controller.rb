# app/controllers/account_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Manage user accounts as represented in the User table ("/account" pages).
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

  authorize_resource instance_name: :item, class: User

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

  # === GET /account
  #
  # List all user accounts.
  #
  # @see #users_path                  Route helper
  # @see #account_index_path          Route helper
  # @see AccountConcern#get_accounts
  #
  def index
    __log_activity
    __debug_route
    prm    = paginator.initial_parameters
    search = prm.delete(:like)
    prm.except!(:limit, *Paginator::PAGINATION_KEYS)
    result = { list: get_accounts(*search, **prm) }
    @list  = paginator.finalize(result, **prm)
  end

  # === GET /account/show/(:id)
  #
  # Display details of an existing EMMA user account.
  #
  # Redirects to #show_select if :id is not given.
  #
  # @see #show_account_path           Route helper
  #
  def show
    __log_activity
    __debug_route
    return redirect_to action: :show_select if identifier.blank?
    @item = get_record
    user_authorize!(__method__, @item)
    # noinspection RubyMismatchedArgumentType
    raise "Record #{quote(identifier)} not found" if @item.blank? # TODO: I18n
  rescue => error
    error_response(error, show_select_account_path)
  end

  # === GET /account/new
  #
  # Display a form for creation of a new EMMA user account.
  #
  # @see #new_account_path            Route helper
  #
  def new
    __log_activity
    __debug_route
    @item = new_record
    user_authorize!(__method__, @item)
  rescue => error
    failure_status(error)
  end

  # === POST  /account/create
  # === PUT   /account/create
  # === PATCH /account/create
  #
  # Create a new EMMA user account.
  #
  # === Usage Notes
  # In order to allow the database to auto-generate the record ID, the :id
  # parameter will be rejected unless "force_id=true" is included in the URL
  # parameters.
  #
  # @see #create_account_path         Route helper
  #
  def create
    __log_activity
    __debug_route
    @item  = create_record(no_raise: true)
    errors = @item&.errors || 'Not created' # TODO: I18n
    user_authorize!(__method__, @item)
    respond_to do |format|
      if errors.blank?
        format.html { redirect_success(__method__) }
        format.json { render :show, location: @item, status: :created }
      else
        format.html { redirect_failure(__method__, error: errors) }
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === GET /account/edit/(:id)
  #
  # Display a form for modification of an existing EMMA user account.
  #
  # Redirects to #edit_select if :id is not given.
  #
  # @see #edit_account_path           Route helper
  #
  def edit
    __log_activity
    __debug_route
    return redirect_to action: :edit_select if identifier.blank?
    @item = edit_record
    user_authorize!(__method__, @item)
    # noinspection RubyMismatchedArgumentType
    raise "Record #{quote(identifier)} not found" if @item.blank? # TODO: I18n
  rescue => error
    error_response(error, edit_select_account_path)
  end

  # === PUT   /account/update/:id
  # === PATCH /account/update/:id
  #
  # Update an existing EMMA user account.
  #
  # @see #update_account_path         Route helper
  #
  def update
    __log_activity
    __debug_route
    __debug_request
    @item  = update_record(no_raise: true)
    errors = @item&.errors || "#{params[:id]} not found" # TODO: I18n
    user_authorize!(__method__, @item)
    respond_to do |format|
      if errors.blank?
        format.html { redirect_success(__method__) }
        format.json { render :show, location: @item, status: :ok }
      else
        format.html { redirect_failure(__method__, error: errors) }
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  rescue => error
    post_response(error, redirect: edit_select_account_path)
  end

  # === GET /account/delete/(:id)
  #
  # Select existing EMMA user account(s) to remove.
  #
  # Redirects to #delete_select if :id is not given.
  #
  # @see #delete_account_path         Route helper
  #
  def delete
    __log_activity
    __debug_route
    return redirect_to action: :delete_select if identifier.blank?
    @list = delete_records[:list]
    user_authorize!(__method__, @list)
    unless @list.present? || last_operation_path&.include?('/destroy')
      # noinspection RubyMismatchedArgumentType
      raise "No records match #{quote(identifier_list)}" # TODO: I18n
    end
  rescue => error
    error_response(error, delete_select_account_path)
  end

  # === DELETE /account/destroy/:id
  #
  # Remove existing EMMA user account(s).
  #
  # @see #destroy_account_path        Route helper
  #
  #--
  # noinspection RubyScope
  #++
  def destroy
    __log_activity
    __debug_route
    back  = delete_select_account_path
    @list = destroy_records
    # user_authorize!(__method__, @list) # TODO: authorize :destroy
    post_response(:ok, @list, redirect: back)
  rescue Record::SubmitError => error
    post_response(:conflict, error, redirect: back)
  rescue => error
    post_response(error, redirect: back)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /account/show_select
  #
  # Show a menu to select a user to show.
  #
  # @see #show_select_account_path    Route helper
  #
  def show_select
    __log_activity
    __debug_route
  end

  # === GET /account/edit_select
  #
  # Show a menu to select a user to edit.
  #
  # @see #edit_select_account_path    Route helper
  #
  def edit_select
    __log_activity
    __debug_route
  end

  # === GET /account/delete_select
  #
  # Show a menu to select a user to delete.
  #
  # @see #delete_select_account_path  Route helper
  #
  def delete_select
    __log_activity
    __debug_route
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # This is a kludge until I can figure out the right way to express this with
  # CanCan -- or replace CanCan with a more expressive authorization gem.
  #
  # @param [Symbol]                 action
  # @param [User, Array<User>, nil] subject
  # @param [*]                      args
  #
  def user_authorize!(action, subject, *args)
    subject = subject.first if subject.is_a?(Array) # TODO: per item check
    subject = subject.presence
    authorize!(action, subject, *args) if subject
    return if administrator?
    return unless %i[show edit update delete destroy].include?(action)
    unless (org = current_user&.org&.id) && (subject&.org&.id == org)
      message = current_ability.unauthorized_message(action, subject)
      message.sub!(/s\.?$/, " #{subject.id}") if subject
      raise CanCan::AccessDenied.new(message, action, subject, args)
    end
  end

end

__loading_end(__FILE__)
