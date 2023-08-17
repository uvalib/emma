# app/controllers/org_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Manage organizations ("/org" pages).
#
# @see OrgDecorator
# @see OrgsDecorator
# @see file:app/views/org/**
#
class OrgController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include OrgConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource instance_name: :item

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section:
  # ===========================================================================

  OPS   = %i[new edit delete].freeze
  MENUS = %i[show_select edit_select delete_select].freeze

  respond_to :html
  respond_to :json, :xml, except: OPS + MENUS

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Results for :index.
  #
  # @return [Array<Org>]
  # @return [Array<String>]
  # @return [nil]
  #
  attr_reader :list

  # Single item.
  #
  # @return [Org, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /org
  #
  # List all organizations.
  #
  # @see #org_index_path          Route helper
  #
  def index
    __log_activity
    __debug_route
    id  = identifier || current_id
    prm = paginator.initial_parameters.except(*Paginator::NON_SEARCH_KEYS)
    if id.blank? && prm.present?
      # Perform search here.
      sort  = prm.delete(:sort) || { updated_at: :desc }
      found = find_or_match_records(sort: sort, **prm)
      @list = paginator.finalize(found, **prm)
    else
      # Otherwise redirect to the appropriate list action.
      if id.blank?
        prm.merge!(action: :list_all)
      else
        prm.merge!(action: :show, id: id)
      end
      respond_to do |format|
        format.html { redirect_to prm }
        format.json { redirect_to prm.merge!(format: :json) }
        format.xml  { redirect_to prm.merge!(format: :xml) }
      end
    end
  rescue Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /org/show/(:id)
  #
  # Display details of an existing EMMA member organization.
  #
  # If :id is not given then #current_org is used.
  #
  # @see #show_org_path          Route helper
  #
  def show
    __log_activity
    __debug_route
    case
      when identifier  then @item = get_record
      when current_org then @item = current_org
      else                  return redirect_to action: :show_select
    end
    org_authorize!
  rescue => error
    error_response(error, show_select_org_path)
  end

  # === GET /org/new
  #
  # @see #new_org_path           Route helper
  #
  def new
    __log_activity
    __debug_route
    @item = new_record
    org_authorize!
  rescue => error
    failure_status(error)
  end

  # === POST  /org/create
  # === PUT   /org/create
  # === PATCH /org/create
  #
  # @see #create_org_path        Route helper
  #
  def create
    __log_activity
    __debug_route
    @item = create_record
    org_authorize!
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: org_index_path)
    end
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === GET /org/edit/(:id)
  #
  # If :id is not given then #current_org is used.
  #
  # @see #edit_org_path          Route helper
  #
  def edit
    __log_activity
    __debug_route
    case
      when identifier  then @item = edit_record
      when current_org then @item = current_org
      else                  return redirect_to action: :edit_select
    end
    org_authorize!
    # noinspection RubyMismatchedArgumentType
    raise "Record #{quote(identifier)} not found" if @item.blank? # TODO: I18n
  rescue => error
    error_response(error, edit_select_org_path)
  end

  # === POST  /org/update/:id
  # === PUT   /org/update/:id
  # === PATCH /org/update/:id
  #
  # @see #update_org_path        Route helper
  #
  def update
    __log_activity
    __debug_route
    __debug_request
    @item = update_record
    org_authorize!
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: org_index_path)
    end
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === GET /org/delete/(:id)
  #
  # Redirects to #delete_select if :id is not given.
  #
  # @see #delete_org_path        Route helper
  #
  def delete
    __log_activity
    __debug_route
    return redirect_to action: :delete_select if identifier.blank?
    raise 'Cannot delete your own organization' if identifier == current_id # TODO: I18n
    @list = delete_records[:list]
    #org_authorize!(@list) # TODO: authorize :delete
    unless @list.present? || last_operation_path&.include?('/destroy')
      # noinspection RubyMismatchedArgumentType
      raise "No records match #{quote(identifier_list)}" # TODO: I18n
    end
  rescue => error
    error_response(error, delete_select_org_path)
  end

  # === DELETE /org/destroy/:id
  #
  # @see #destroy_org_path       Route helper
  #
  #--
  # noinspection RubyScope
  #++
  def destroy
    __log_activity
    __debug_route
    back  = delete_select_org_path
    raise 'Cannot delete your own organization' if current_org # TODO: I18n
    @list = destroy_records
    #org_authorize!(@list) # TODO: authorize :destroy
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

  # === GET /org/list_all
  #
  # List all organizations.
  #
  def list_all
    __log_activity
    __debug_route
    prm   = paginator.initial_parameters.except(*Paginator::NON_SEARCH_KEYS)
    sort  = prm.delete(:sort) || { updated_at: :desc }
    found = find_or_match_records(sort: sort, **prm)
    @list = paginator.finalize(found, **prm)
    respond_to do |format|
      format.html { render 'org/index' }
      format.json { render 'org/index' }
      format.xml  { render 'org/index' }
    end
  rescue Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /org/show_select
  #
  # Show a menu to select an organization to show.
  #
  # @see #show_select_org_path        Route helper
  #
  def show_select
    __log_activity
    __debug_route
  end

  # === GET /org/edit_select
  #
  # Show a menu to select an organization to edit.
  #
  # @see #edit_select_org_path        Route helper
  #
  def edit_select
    __log_activity
    __debug_route
  end

  # === GET /org/delete_select
  #
  # Show a menu to select an organization to delete.
  #
  # @see #delete_select_org_path      Route helper
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
  # @param [Org, Array<Org>, nil] subject
  # @param [Symbol, String, nil]  action
  # @param [*]                    args
  #
  def org_authorize!(subject = nil, action = nil, *args)
    action  ||= request_parameters[:action]
    action    = action.to_sym if action.is_a?(String)
    subject ||= @item
    subject   = subject.first if subject.is_a?(Array) # TODO: per item check
    authorize!(action, subject, *args) if subject
    return if administrator?
    return unless %i[show edit update delete destroy].include?(action)
    unless (org = current_id) && (subject&.id == org)
      message = current_ability.unauthorized_message(action, subject)
      message.sub!(/s\.?$/, " #{subject.id}") if subject
      raise CanCan::AccessDenied.new(message, action, subject, args)
    end
  end

end

__loading_end(__FILE__)
