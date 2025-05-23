# app/controllers/enrollment_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/enrollment" requests.
#
class EnrollmentController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include EnrollmentConcern

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include AbstractController::Callbacks
  end
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  ANON_OPS = %i[new create].freeze

  before_action :update_user
  before_action :authenticate_admin!, except: ANON_OPS

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check only: ANON_OPS

  authorize_resource instance_name: :item

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  MENUS = %i[show_select edit_select delete_select].freeze
  OPS   = %i[new edit delete].freeze

  # None

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  respond_to :html
  respond_to :json, :xml, except: [*MENUS, *OPS]

  # ===========================================================================
  # :section: Values
  # ===========================================================================

  public

  # API results for :index.
  #
  # @return [Array<Enrollment>]
  #
  attr_reader :list

  # API results for :show.
  #
  # @return [Enrollment, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /enrollment
  #
  # List EMMA enrollment requests.
  #
  # @see #enrollment_index_path               Route helper
  #
  def index
    __log_activity
    __debug_route
    return redirect_to action: :show if identifier.present?
    prm   = paginator.initial_parameters
    items = find_or_match_records(**prm)
    paginator.finalize(items, **prm)
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error)
  end

  # === GET /enrollment/:id
  #
  # Display details of a EMMA enrollment request.
  #
  # @see #show_enrollment_path        Route helper
  #
  def show
    __log_activity
    __debug_route
    id = identifier
    return redirect_to action: :show_select if id.blank?
    @item = find_record
    raise config_term(:enrollment, :not_found, id: id) if @item.blank?
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error)
  end

  # === GET /enrollment/new
  #
  # For the deployed production application, a request ticket is generated for
  # the new enrollment unless "ticket=false" appears in URL parameters.
  # Otherwise, a request ticket is generated *only* if "ticket=true" appears in
  # URL parameters.
  #
  # This parameter (if provided) is passed to the :create endpoint via a hidden
  # form parameter.
  #
  # @see #new_enrollment_path             Route helper
  # @see EnrollmentDecorator#form_hidden
  #
  def new
    __log_activity
    __debug_route
    @item = new_record
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    failure_status(error)
  end

  # === POST  /enrollment/create
  # === PUT   /enrollment/create
  # === PATCH /enrollment/create
  #
  # For the deployed production application, a request ticket is generated for
  # the new enrollment unless "ticket=false" appears in the form parameters.
  #
  # Otherwise, a request ticket is generated *only* if "ticket=true" appears in
  # the form parameters.
  #
  # @see #create_enrollment_path                  Route helper
  #
  def create
    redir = post_redirect(welcome_path)
    __log_activity
    __debug_route
    @item = create_record
    generate_enrollment_ticket(@item) if send_help_ticket?
    if request_xhr?
      render json: @item.as_json
    else
      post_response(@item, redirect: redir)
    end
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue Record::SubmitError => error
    redir &&= redir_params(action: :new)
    post_response(:conflict, error, redirect: redir)
  rescue => error
    post_response(error, redirect: redir)
  end

  # === GET /enrollment/edit/(:id)
  #
  # Display a form for modification of an existing EMMA enrollment request.
  #
  # Redirects to #edit_select if :id is not given.
  #
  # @see #edit_enrollment_path          Route helper
  #
  def edit
    __log_activity
    __debug_route
    return redirect_to action: :edit_select if identifier.blank?
    @item = edit_record
    raise config_term(:enrollment, :not_found, id: identifier) if @item.blank?
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, edit_select_enrollment_path)
  end

  # === POST  /enrollment/update/:id
  # === PUT   /enrollment/update/:id
  # === PATCH /enrollment/update/:id
  #
  # @see #update_enrollment_path          Route helper
  #
  def update
    redir = post_redirect(edit_select_enrollment_path)
    __log_activity
    __debug_route
    __debug_request
    @item = update_record
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: redir)
    end
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === GET /enrollment/delete/(:id)
  #
  # Redirects to #delete_select if :id is not given.
  #
  # @see #delete_enrollment_path            Route helper
  #
  def delete
    __log_activity
    __debug_route
    return redirect_to action: :delete_select if identifier.blank?
    @list = delete_records.list&.records
    unless @list.present? || last_operation_path&.include?('/destroy')
      raise config_term(:enrollment, :no_match, id: identifier_list)
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, delete_select_enrollment_path)
  end

  # === DELETE /enrollment/destroy/:id
  #
  # @see #destroy_enrollment_path           Route helper
  #
  def destroy
    redir = post_redirect(delete_select_enrollment_path)
    __log_activity
    __debug_route
    @list = destroy_records
    post_response(:ok, @list, redirect: redir)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue Record::SubmitError => error
    post_response(:conflict, error, redirect: redir)
  rescue => error
    post_response(error, redirect: redir)
  end

  # ===========================================================================
  # :section: Routes - Menu
  # ===========================================================================

  public

  # === GET /enrollment/show_select
  #
  # Show a menu to select a EMMA enrollment request to show.
  #
  # @see #show_select_enrollment_path     Route helper
  #
  def show_select
    __log_activity
    __debug_route
  end

  # === GET /enrollment/edit_select
  #
  # Show a menu to select a EMMA enrollment request to edit.
  #
  # @see #edit_select_enrollment_path     Route helper
  #
  def edit_select
    __log_activity
    __debug_route
  end

  # === GET /enrollment/delete_select
  #
  # Show a menu to select a EMMA enrollment request to delete.
  #
  # @see #delete_select_enrollment_path   Route helper
  #
  def delete_select
    __log_activity
    __debug_route
  end

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  # === POST  /enrollment/finalize/:id
  #
  # Finalize an EMMA enrollment request by creating a new Org and User, and
  # removing the Enrollment record.
  #
  # @see #finalize_enrollment_path        Route helper
  #
  def finalize
    __log_activity
    __debug_route
    __debug_request
    @item = finalize_enrollment
    raise config_term(:enrollment, :not_found, id: identifier) if @item.blank?
    generate_new_users_emails if new_users_email?
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: enrollment_index_path)
    end
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

end

__loading_end(__FILE__)
