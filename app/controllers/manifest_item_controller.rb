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
  include SerializationConcern
  include ManifestItemConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include AbstractController::Callbacks
    include ActionController::RespondWith
    extend  CanCan::ControllerAdditions::ClassMethods
    # :nocov:
  end

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html
  respond_to :json, :xml, except: %i[edit]

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Results for :index.
  #
  # @return [Array<ManifestItem>]
  # @return [Array<String>]
  # @return [nil]
  #
  attr_reader :list

  # API results for :show.
  #
  # @return [ManifestItem, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /manifest_item/:manifest[?id=(:id|RANGE_LIST)]
  #
  # Display the items for the given Manifest.
  #
  # @see #manifest_item_index_path                 Route helper
  # @see ManifestItemConcern#find_or_match_manifest_items
  #
  def index
    __log_activity
    __debug_route
    prm    = paginator.initial_parameters
    prm.except!(:group, :groups) # TODO: groups
    all    = prm[:group].nil? || (prm[:group].to_sym == :all)
    result = find_or_match_manifest_items(groups: all, **prm)
    @list  = paginator.finalize(result, **prm)
    result = find_or_match_manifest_items(groups: :only, **prm) if prm.delete(:group)
    @group_counts = result[:groups]
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  rescue Record::SubmitError => error
    show_search_failure(error)
  rescue => error
    show_search_failure(error, root_path)
  end

  # == GET /manifest_item/show/:manifest/:id
  #
  # Display the values of a single manifest item.
  #
  # @see #show_manifest_item_path                  Route helper
  # @see ManifestItemConcern#get_manifest_item
  #
  def show
    __log_activity
    __debug_route
    @item = get_manifest_item
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue => error
    show_search_failure(error)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # == GET /manifest_item/new/:manifest
  #
  # Initiate creation of a new ManifestItem by displaying the form which
  # prompts to upload a file and collects metadata for the new item.
  #
  # @see #new_manifest_item_path                   Route helper
  # @see ManifestItemConcern#new_manifest_item
  # @see ManifestItemController#create
  # @see file:app/assets/javascripts/feature/model-form.js
  #
  def new
    __debug_route
    @item = new_manifest_item(**manifest_item_params)
  rescue => error
    failure_status(error)
  end

  # == POST  /manifest_item/create/:manifest
  # == PUT   /manifest_item/create/:manifest
  # == PATCH /manifest_item/create/:manifest
  #
  # @see #create_manifest_item_path                Route helper
  # @see ManifestItemConcern#create_manifest_item
  # @see ManifestItemController#new
  #
  def create
    __debug_route
    @item = create_manifest_item(**manifest_item_params)
    #redir = (manifest_item_index_path unless request_xhr?)
    #post_response(:ok, @item, redirect: redir)
    success = @item.errors.blank?
    respond_to do |format|
      if success
        format.html { redirect_to(action: :index) }
        format.json { render json: @item, status: :created }
      else
        # @type [ActiveModel::Errors]
        errors = @item.errors
        format.html { redirect_failure(__method__, error: errors) }
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  rescue => error
    post_response(error)
  end

  # == GET /manifest_item/edit/:manifest/:id
  #
  # Initiate modification of an existing item by prompting for metadata
  # changes and/or upload of a replacement file.
  #
  # @see #edit_manifest_item_path                  Route helper
  # @see ManifestItemConcern#edit_manifest_item
  # @see ManifestItemController#update
  # @see file:app/assets/javascripts/feature/model-form.js
  #
  def edit
    __debug_route
    @item = edit_manifest_item(**manifest_item_params)
  rescue => error
    failure_status(error)
  end

  # == PUT   /manifest_item/update/:manifest/:id
  # == PATCH /manifest_item/update/:manifest/:id
  #
  # Finalize modification of an existing item.
  #
  # @see #update_manifest_item_path                Route helper
  # @see ManifestItemConcern#update_manifest_item
  # @see ManifestItemController#edit
  #
  def update
    __debug_route
    __debug_request
    @item = update_manifest_item(**manifest_item_params)
    post_response(:ok, @item, redirect: manifest_item_index_path)
  rescue => error
    post_response(error)
  end

  # == GET /manifest_item/delete/:manifest/:id
  # == GET /manifest_item/delete/:manifest/RANGE_LIST[?...]
  #
  # Initiate removal of an existing item along with its associated file.
  #
  # @see #delete_manifest_item_path                Route helper
  # @see ManifestItemConcern#delete_manifest_item
  # @see ManifestItemController#destroy
  #
  def delete
    __debug_route
    items = delete_manifest_item(**manifest_item_params)
    @list = items[:list]
  rescue => error
    failure_status(error)
  end

  # == DELETE /manifest_item/destroy/:manifest/:id
  # == DELETE /manifest_item/destroy/:manifest/RANGE_LIST[?...]
  #
  # Finalize removal of an existing item.
  #
  # @see #destroy_manifest_item_path               Route helper
  # @see ManifestItemConcern#destroy_manifest_item
  # @see ManifestItemController#delete
  #
  def destroy
    __debug_route
    @list = destroy_manifest_item(**manifest_item_params)
    post_response(:ok, @list, redirect: :back)
  rescue => error
    post_response(error, redirect: :back)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # == POST /manifest_item/start_edit/:id
  #
  # Set :editing state and backup fields.
  #
  # @see #start_editing_manifest_item_path               Route helper
  #
  def start_edit
    __debug_route
    @item = start_editing(**manifest_item_params)
    post_response(:ok)
  rescue => error
    post_response(error)
  end

  # == POST /manifest_item/finish_edit/:id
  #
  # Clear :editing state and respond with item and validity information.
  #
  def finish_edit
    __debug_route
    render_json finish_editing(**manifest_item_params)
  rescue => error
    post_response(error)
  end

  # == POST /manifest_item/finish_edit/:id
  #
  # Clear :editing state and respond with item and validity information.
  #
  def row_update
    __debug_route
    render_json editing_update(**manifest_item_params)
  rescue => error
    post_response(error)
  end

  # == POST /manifest_item/upload
  #
  # Invoked from 'Uppy.XHRUpload'.  If the 'X-Update-FileData-Only' header is
  # *true* then the record's :file_data column is updated without modifying
  # :update_time or other columns.
  #
  # @see file:javascripts/shared/uploader.js *BulkUploader._xhrOptions*
  #
  def upload
    __log_activity
    __debug_route
    __debug_request
    prm = manifest_item_params.dup
    id  = extract_hash!(prm, *IDENTIFIER_PARAMS).values.first.presence
    fd  = true?(request.headers['X-Update-FileData-Only'])
    stat, hdrs, body = upload_file(**prm, id: id, update_time: !fd)
    self.status = stat        if stat.present?
    self.headers.merge!(hdrs) if hdrs.present?
    self.response_body = body if body.present?
  rescue Record::SubmitError => error
    post_response(:conflict, error, xhr: true)
  rescue => error
    post_response(error, xhr: true)
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  public

  # == GET /manifest_item/bulk/new/:manifest
  #
  # Display a form prompting for a bulk operation manifest (either CSV or JSON)
  # containing a row/element for each item to add.
  #
  # @see #bulk_new_manifest_item_path              Route helper
  # @see ManifestItemConcern#bulk_new_manifest_items
  # @see ManifestItemController#bulk_create
  #
  def bulk_new
    __debug_route
    bulk_new_manifest_items
  rescue => error
    failure_status(error)
  end

  # == POST /manifest_item/bulk/create/:manifest
  #
  # Create the specified ManifestItem records, download and store the
  # associated files.
  #
  # @see #bulk_create_manifest_item_path           Route helper
  # @see ManifestItemConcern#bulk_create_manifest_items
  # @see ManifestItemController#bulk_new
  #
  def bulk_create
    __debug_route
    __debug_request
    @list = bulk_create_manifest_items
    render_json bulk_update_response
  rescue => error
    post_response(error)
  end

  # == GET /manifest_item/bulk/edit/:manifest
  #
  # Display a form prompting for a bulk operation manifest (either CSV or JSON)
  # containing a row/element for each item to change.
  #
  # @see #bulk_edit_manifest_item_path             Route helper
  # @see ManifestItemConcern#bulk_edit_manifest_items
  # @see ManifestItemController#bulk_update
  #
  def bulk_edit
    __debug_route
    @list = bulk_edit_manifest_items
  rescue => error
    failure_status(error)
  end

  # == PUT   /manifest_item/bulk/update/:manifest
  # == PATCH /manifest_item/bulk/update/:manifest
  #
  # Modify or create the specified ManifestItem records, download and store the
  # associated files (if changed).
  #
  # @see #bulk_update_manifest_item_path           Route helper
  # @see ManifestItemConcern#bulk_update_manifest_items
  # @see ManifestItemController#bulk_edit
  #
  def bulk_update
    __debug_route
    __debug_request
    @list = bulk_update_manifest_items
    render_json bulk_update_response
  rescue => error
    post_response(error)
  end

  # == GET /manifest_item/bulk/delete/:manifest
  #
  # Specify items to delete by :id or RANGE_LIST.
  #
  # @see #bulk_delete_manifest_item_path           Route helper
  # @see ManifestItemConcern#bulk_delete_manifest_items
  # @see ManifestItemController#bulk_destroy
  #
  def bulk_delete
    __debug_route
    @list = bulk_delete_manifest_items
  rescue => error
    failure_status(error)
  end

  # == DELETE /manifest_item/bulk/destroy/:manifest
  #
  # @see #bulk_destroy_manifest_item_path          Route helper
  # @see ManifestItemConcern#bulk_destroy_manifest_items
  # @see ManifestItemController#bulk_delete
  #
  def bulk_destroy
    __debug_route
    __debug_request
    @list = bulk_destroy_manifest_items
    render_json bulk_id_response
  rescue => error
    post_response(error, xhr: false)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Display the failure on the screen -- immediately if modal, or after a
  # redirect otherwise.
  #
  # @param [Exception] error
  # @param [String]    fallback   Def.: #manifest_item_index_path
  # @param [Symbol]    meth       Calling method.
  #
  # @return [void]
  #
  def show_search_failure(error, fallback = nil, meth: nil)
    re_raise_if_internal_exception(error)
    meth ||= calling_method
    if modal?
      failure_status(error, meth: meth)
    else
      flash_failure(error, meth: meth)
      redirect_back(fallback_location: (fallback || manifest_item_index_path))
    end
  end

  # A list of ManifestItems plus validity information.
  #
  # @param [*]       list
  # @param [Hash]    opt              Passed to #index_values.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def bulk_update_response(list = @list, **opt)
    index_values(list, **opt)
  end

  # A list of ManifestItem IDs.
  #
  # @param [*] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def bulk_id_response(list = @list, **)
    list = list.is_a?(Array) ? list.dup : Array.wrap(list)
    list.map! { |item| item.try(:id) || item }.compact_blank!.map!(&:to_i)
    { RESPONSE_OUTER => { list: list } }
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # @private
  RESPONSE_OUTER = :items

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [*]      list
  # @param [Symbol] wrap
  # @param [Hash]   opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, wrap: RESPONSE_OUTER, **opt)
    super(list, **opt, wrap: wrap)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Model, Hash, *] item
  # @param [Hash]           opt
  #
  # @return [Hash{Symbol=>*}]
  #
  def show_values(item = @item, **opt)
    if item.is_a?(Model) || item.is_a?(Hash)
      # noinspection RailsParamDefResolve
      item = item.try(:fields) || item.dup
      file = item.delete(:file_data)
      item[:file_data] = safe_json_parse(file) if file
    end
    super(item, **opt)
  end

end

__loading_end(__FILE__)
