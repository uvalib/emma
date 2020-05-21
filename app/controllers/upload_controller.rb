# app/controllers/upload_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# UploadController
#
class UploadController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include UploadConcern

  # Non-functional hints for RubyMine.
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!, except: %i[show]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # The @item_id member variable contains the original item specification, if
  # one was provided, and not the array of IDs represented by it.
  before_action(only: %i[index show edit delete destroy]) do
    @item_id = params[:selected] || params[:repository_id] || params[:id]
    @item_id = @item_id.presence
  end

  respond_to :html
  respond_to :json, :xml, except: %i[edit] # TODO: ???

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /upload[?(id|repository_id|selected)=ITEM_SPEC]
  # Display the current user's uploads.
  #
  # If an item specification is given via the :id, :repository_id, or :selected
  # option then the results will be limited to the matching upload(s).
  # NOTE: Currently this is not limited only to the current user's uploads.
  #
  # @see Upload#get_records
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = nil
    @list ||= (Upload.get_records(*@item_id) if @item_id)
    @list ||= (Upload.get_records(*@item_id, user_id: @user.id) if @user)
    @list ||= []
    self.page_items  = @list
    self.total_items = @list.size
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html { render layout: layout }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end

  rescue => error
    flash_failure(error)
    redirect_back(fallback_location: root_path)

  end

  # == GET /upload/:id
  # == GET /upload/ITEM_SPEC
  # Display a single upload.
  #
  # @see Upload#get_record
  #
  def show
    __debug_route
    fail(:file_id) if @item_id.blank?
    @item = Upload.get_record(@item_id) or fail(:find, @item_id)
    respond_to do |format|
      format.html { render layout: layout }
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end

  rescue => error
    flash_failure(error)
    redirect_back(fallback_location: upload_index_path)

  end

  # == GET /upload/new
  # Initiate creation of a new EMMA entry by prompting to upload a file.
  #
  # @see Upload#initialize
  #
  def new
    __debug_route
    @item = Upload.new(user_id: @user.id)
    respond_with(@item)

  rescue => error
    flash_now_failure(error)

  end

  # == POST /upload
  # Invoked from the handler for the Uppy 'upload-success' event to finalize
  # the creation of a new EMMA entry.
  #
  # @see UploadConcern#finalize_upload
  # @see app/assets/javascripts/feature/file-upload.js
  #
  def create
    __debug_route
    data  = upload_post_parameters.merge!(user_id: @user.id)
    @item = Upload.new(data) or fail(__method__)
    @item.save
    @item.errors.blank?      or fail(@item.errors)
    finalize_upload(@item)
    post_response(:ok, @item.filename, redirect: upload_index_path)

  rescue SubmitError => error
    post_response(:conflict, error) # TODO: ?

  rescue => error
    post_response(error)

  end

  # == GET /upload/:id/edit
  # == GET /upload/SELECT/edit
  # Initiate modification of an existing EMMA entry by prompting for metadata
  # changes and/or upload of a replacement file.
  #
  # @see Upload#get_record
  #
  def edit
    __debug_route
    fail(:file_id) if @item_id.blank?
    @item = nil
    unless @item_id == 'SELECT'
      @item = Upload.get_record(@item_id) or fail(:find, @item_id)
    end

  rescue => error
    flash_now_failure(error)

  end

  # == PUT   /upload/:id
  # == PATCH /upload/:id
  # Finalize modification of an existing EMMA entry.
  #
  # @see Upload#get_record
  # @see UploadConcern#finalize_upload
  #
  def update
    __debug_route
    __debug_request
    data = upload_post_parameters
    id   = data.delete(:id)       or fail(:file_id)
    @item = Upload.get_record(id) or fail(:find, id)
    @item.update(data)
    @item.errors.blank?           or fail(@item.errors)
    finalize_upload(@item)
    post_response(:ok, @item.filename, redirect: upload_index_path)

  rescue SubmitError => error
    post_response(:conflict, error) # TODO: ?

  rescue => error
    post_response(error)

  end

  # == GET /upload/delete/:id[?force=true]
  # == GET /upload/delete/SELECT
  # Initiate removal of an existing EMMA entry along with its associated file.
  #
  # Use :force to attempt to remove an item from the EMMA Unified Search index
  # even if a database record was not found.
  #
  # @see Upload#get_record
  #
  def delete
    __debug_route
    ids    = Upload.collect_ids(@item_id).presence or fail(:file_id)
    @force = true?(params[:force])
    @list  = nil
    unless ids.include?('SELECT')
      @list =
        ids.map do |id|
          record = Upload.get_record(id)
          fail(:find, id) unless record || @force
          record || id
        end
    end

  rescue => error
    flash_now_failure(error)

  end

  # == DELETE /upload/:id[?force=true]
  # == DELETE /upload/ITEM_SPEC[?force=true]
  # Finalize removal of an existing EMMA entry.
  #
  # @see UploadConcern#destroy_upload
  #
  # noinspection RubyScope
  def destroy
    __debug_route
    ids    = Upload.collect_ids(@item_id).presence or fail(:file_id)
    @force = true?(params[:force])
    back   = delete_select_upload_path
    succeeded, failed = destroy_upload(ids, force: @force)
    fail(:find, failed) unless failed.blank? || @force
    post_response(:found, succeeded, redirect: back)

  rescue SubmitError => error
    post_response(:conflict, error, redirect: back) # TODO: ?

  rescue => error
    post_response(:not_found, error, redirect: back)

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == POST /upload/endpoint
  # Invoked from 'Uppy.XHRUpload'.
  #
  # @see Shrine::Plugins::UploadEndpoint::ClassMethods#upload_response
  # @see app/assets/javascripts/feature/file-upload.js
  #
  def endpoint
    __debug_route
    __debug_request
    stat, hdrs, body = FileUploader.upload_response(:cache, request.env)
    self.status = stat        if stat.present?
    self.headers.merge!(hdrs) if hdrs.present?
    self.response_body = body if body.present?

  rescue SubmitError => error
    post_response(:conflict, error, xhr: true) # TODO: ?

  rescue => error
    post_response(error, xhr: true)

  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Array<Upload>] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { entries: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Upload, Hash] item
  #
  # @return [Hash{Symbol=>*}]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item)
    item = item.attributes.symbolize_keys if item.is_a?(Upload)
    data = item.extract!(:file_data).first.last
    item[:file_data] = safe_json_parse(data)
    { entry: item }
  end

end

__loading_end(__FILE__)
