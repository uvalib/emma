# app/controllers/manifest_item_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/manifest_item" requests.
#
# @see ManifestItemDecorator
# @see ManifestItemsDecorator
# @see file:app/views/manifest_item/**
#
class ManifestItemController < ApplicationController

  include UserConcern
  include ParamsConcern
  include OptionsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include ManifestItemConcern

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include AbstractController::Callbacks
    include ActionController::RespondWith
    extend  CanCan::ControllerAdditions::ClassMethods
  end
  # :nocov:

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

  MENUS    = %i[show_select edit_select delete_select].freeze
  UNIT_OPS = %i[new edit delete].freeze
  BULK_OPS = %i[bulk_new bulk_edit bulk_delete].freeze
  OPS      = [*UNIT_OPS, *BULK_OPS].freeze

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

  # API results for :show.
  #
  # @return [ManifestItem, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /manifest_item/:manifest[?id=(:id|RANGE_LIST)]
  #
  # Display the items for the given Manifest.
  #
  # @see #manifest_item_index_path                 Route helper
  #
  def index
    __log_activity
    __debug_route
    prm   = paginator.initial_parameters
    prm.except!(:group, :groups) # TODO: groups
    all   = prm[:group].nil? || (prm[:group].to_sym == :all)
    items = find_or_match_records(groups: all, **prm)
    paginator.finalize(items, **prm)
    items = find_or_match_records(groups: :only, **prm) if prm.delete(:group)
    @group_counts = items[:groups]
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /manifest_item/show/:manifest/:id
  #
  # Display the values of a single manifest item.
  #
  # @see #show_manifest_item_path                  Route helper
  #
  def show
    __log_activity
    __debug_route
    @item = find_record
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error)
  end

  # ===========================================================================
  # :section: Routes - Workflow - Single
  # ===========================================================================

  public

  # === GET /manifest_item/new/:manifest
  #
  # Initiate creation of a new ManifestItem by displaying the form which
  # prompts to upload a file and collects metadata for the new item.
  #
  # @see #new_manifest_item_path                   Route helper
  # @see ManifestItemController#create
  # @see file:app/assets/javascripts/feature/model-form.js
  #
  def new
    __debug_route
    @item = new_record
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    failure_status(error)
  end

  # === POST  /manifest_item/create/:manifest
  # === PUT   /manifest_item/create/:manifest
  # === PATCH /manifest_item/create/:manifest
  #
  # @see #create_manifest_item_path                Route helper
  # @see ManifestItemController#new
  #
  def create
    __debug_route
    @item = create_record
    #redir = (manifest_item_index_path unless request_xhr?)
    #post_response(:ok, @item, redirect: redir)
    errors = @item.errors
    respond_to do |format|
      if errors.blank?
        format.html { redirect_to(action: :index) }
        format.json { render json: @item, status: :created }
      else
        format.html { error_response(@item || errors) }
        format.json { render json: errors, status: :unprocessable_content }
      end
    end
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error)
  end

  # === GET /manifest_item/edit/:manifest/:id
  #
  # Initiate modification of an existing item by prompting for metadata
  # changes and/or upload of a replacement file.
  #
  # @see #edit_manifest_item_path                  Route helper
  # @see ManifestItemController#update
  # @see file:app/assets/javascripts/feature/model-form.js
  #
  def edit
    __debug_route
    @item = edit_record
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    failure_status(error)
  end

  # === PUT   /manifest_item/update/:manifest/:id
  # === PATCH /manifest_item/update/:manifest/:id
  #
  # Finalize modification of an existing item.
  #
  # @see #update_manifest_item_path                Route helper
  # @see ManifestItemController#edit
  #
  def update
    __debug_route
    __debug_request
    @item = update_record
    post_response(:ok, @item, redirect: manifest_item_index_path)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error)
  end

  # === GET /manifest_item/delete/:manifest/:id
  # === GET /manifest_item/delete/:manifest/RANGE_LIST[?...]
  #
  # Initiate removal of an existing item along with its associated file.
  #
  # @see #delete_manifest_item_path                Route helper
  # @see ManifestItemController#destroy
  #
  def delete
    __debug_route
    @list = delete_records.list&.records
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    failure_status(error)
  end

  # === DELETE /manifest_item/destroy/:manifest/:id
  # === DELETE /manifest_item/destroy/:manifest/RANGE_LIST[?...]
  #
  # Finalize removal of an existing item.
  #
  # @see #destroy_manifest_item_path               Route helper
  # @see ManifestItemController#delete
  #
  def destroy
    __debug_route
    @list = destroy_records
    post_response(:ok, @list, redirect: :back)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error, redirect: :back)
  end

  # ===========================================================================
  # :section: Routes - Workflow - Single
  # ===========================================================================

  public

  # === POST /manifest_item/start_edit/:id
  #
  # Set :editing state and backup fields.
  #
  # @see #start_editing_manifest_item_path               Route helper
  #
  def start_edit
    __debug_route
    @item = start_editing(**current_params)
    post_response(:ok)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error)
  end

  # === POST /manifest_item/finish_edit/:id
  #
  # Clear :editing state and respond with item and validity information.
  #
  # @see ManifestItemConcern#finish_editing
  #
  def finish_edit
    __debug_route
    render_json finish_editing(**current_params)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error)
  end

  # === POST /manifest_item/row_update/:id
  #
  # Clear :editing state and respond with item and validity information.
  #
  def row_update
    __debug_route
    render_json editing_update(**current_params)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error)
  end

  # === POST /manifest_item/upload
  #
  # Invoked from 'Uppy.XHRUpload'.  If the 'X-Update-FileData-Only' header is
  # *true* then the record's :file_data column is updated without modifying
  # :update_time or other columns.
  #
  # @see ManifestItemConcern#upload_file
  # @see file:javascripts/shared/uploader.js *BulkUploader._xhrOptions*
  #
  def upload
    __log_activity
    __debug_route
    __debug_request
    prm = current_params.dup
    ids = prm.extract!(*model_options.identifier_keys)
    id  = ids[:id].presence || ids.values.compact.first
    fd  = true?(request.headers['X-Update-FileData-Only'])
    stat, hdrs, body = upload_file(**prm, id: id, update_time: !fd)
    self.status = stat        if stat.present?
    self.headers.merge!(hdrs) if hdrs.present?
    self.response_body = body if body.present?
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue Record::SubmitError => error
    post_response(:conflict, error, xhr: true)
  rescue => error
    post_response(error, xhr: true)
  end

  # ===========================================================================
  # :section: Routes - Workflow - Bulk
  # ===========================================================================

  public

  # === GET /manifest_item/bulk/new/:manifest
  #
  # Display a form prompting for a bulk operation manifest (either CSV or JSON)
  # containing a row/element for each item to add.
  #
  # @see #bulk_new_manifest_item_path                   Route helper
  # @see ManifestItemController#bulk_create
  #
  def bulk_new
    __debug_route
    bulk_new_manifest_items
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    failure_status(error)
  end

  # === POST /manifest_item/bulk/create/:manifest
  #
  # Create the specified ManifestItem records, download and store the
  # associated files.
  #
  # @see #bulk_create_manifest_item_path                Route helper
  # @see file:javascripts/controllers/manifest-edit.js  *sendUpsertRecords*
  # @see ManifestItemController#bulk_new
  #
  def bulk_create
    __debug_route
    __debug_request
    @list = bulk_create_manifest_items
    render_json bulk_update_response
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error)
  end

  # === GET /manifest_item/bulk/edit/:manifest
  #
  # Display a form prompting for a bulk operation manifest (either CSV or JSON)
  # containing a row/element for each item to change.
  #
  # @see #bulk_edit_manifest_item_path                  Route helper
  # @see ManifestItemController#bulk_update
  #
  def bulk_edit
    __debug_route
    @list = bulk_edit_manifest_items
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    failure_status(error)
  end

  # === PUT   /manifest_item/bulk/update/:manifest
  # === PATCH /manifest_item/bulk/update/:manifest
  #
  # Modify or create the specified ManifestItem records, download and store the
  # associated files (if changed).
  #
  # @see #bulk_update_manifest_item_path                Route helper
  # @see file:javascripts/controllers/manifest-edit.js  *sendUpsertRecords*
  # @see ManifestItemController#bulk_edit
  #
  def bulk_update
    __debug_route
    __debug_request
    @list = bulk_update_manifest_items
    render_json bulk_update_response
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error)
  end

  # === GET /manifest_item/bulk/delete/:manifest
  #
  # Specify items to delete by :id or RANGE_LIST.
  #
  # @see #bulk_delete_manifest_item_path                Route helper
  # @see ManifestItemController#bulk_destroy
  #
  def bulk_delete
    __debug_route
    @list = bulk_delete_manifest_items
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    failure_status(error)
  end

  # === DELETE /manifest_item/bulk/destroy/:manifest
  #
  # Remove the specified ManifestItem records and their associated files.
  #
  # @see #bulk_destroy_manifest_item_path               Route helper
  # @see ManifestItemController#bulk_delete
  #
  def bulk_destroy
    __debug_route
    __debug_request
    @list = bulk_destroy_manifest_items
    render_json bulk_id_response
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error, xhr: false)
  end

  # === PUT   /manifest_item/bulk/fields/:manifest
  # === PATCH /manifest_item/bulk/fields/:manifest
  #
  # Modify selected ManifestItem fields of one or more items.
  #
  # @see #bulk_fields_manifest_item_path                Route helper
  # @see file:javascripts/controllers/manifest-edit.js  *sendFieldUpdates*
  #
  def bulk_fields
    __debug_route
    __debug_request
    @list = bulk_fields_manifest_items
    render_json bulk_update_response
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error)
  end

end

__loading_end(__FILE__)
