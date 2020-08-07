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
  include IaDownloadConcern

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

  before_action :set_item_id,    only: %i[index show edit update delete destroy download]
  before_action :index_redirect, only: %i[show]

  before_action(only: :retrieval) { @url = params[:url] }

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
  # @see UploadConcern#find_records
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = nil
    @list ||= (find_records(@item_id)          if @item_id)
    @list ||= (find_records(user_id: @user.id) if @user)
    @list ||= []
    self.page_items  = @list
    self.total_items = @list.size
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  rescue => error
    show_search_failure(error, root_path)
  end

  # == GET /upload/:id
  # Display a single upload.
  #
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  #
  # @see UploadConcern#get_record
  #
  def show
    __debug_route
    @item = get_record(@item_id)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue SubmitError => error
    unless application_deployed?
      @host = PRODUCTION_BASE_URL
      @item = proxy_get_record(@item_id, @host)
    end
    show_search_failure(error, upload_index_path) if @item.blank?
  rescue => error
    show_search_failure(error, upload_index_path)
  end

  # == GET /upload/new
  # Initiate creation of a new EMMA entry by prompting to upload a file.
  #
  # @see UploadConcern#new_record
  # @see #create
  #
  def new
    __debug_route
    @item = new_record(user_id: @user.id, base_url: request.base_url)
    respond_with(@item)
  rescue => error
    flash_now_failure(error)
  end

  # == POST /upload
  # Invoked from the handler for the Uppy 'upload-success' event to finalize
  # the creation of a new EMMA entry.
  #
  # @raise [Net::HTTPConflict]
  # @raise [UploadConcern::SubmitError]
  #
  # @see UploadConcern#upload_create
  # @see app/assets/javascripts/feature/file-upload.js
  #
  def create
    __debug_route
    data = upload_post_parameters.merge!(user_id: @user.id)
    @item, failed = upload_create(data)
    fail(__method__, failed) if failed.present?
    post_response(:ok, @item, redirect: upload_index_path)
  rescue SubmitError => error
    post_response(:conflict, error) # TODO: ?
  rescue => error
    post_response(error)
  end

  # == GET /upload/edit/:id
  # Initiate modification of an existing EMMA entry by prompting for metadata
  # changes and/or upload of a replacement file.
  #
  # If :id is "SELECT" then a menu of editable items is presented.
  #
  # @see UploadConcern#get_record
  # @see #update
  #
  def edit
    __debug_route
    @item = (get_record(@item_id) unless show_menu?(@item_id))
  rescue => error
    flash_now_failure(error)
  end

  # == PUT   /upload/:id
  # == PATCH /upload/:id
  # Finalize modification of an existing EMMA entry.
  #
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  # @raise [UploadConcern::SubmitError]
  #
  # @see UploadConcern#upload_update
  #
  def update
    __debug_route
    __debug_request
    data = upload_post_parameters.merge!(user_id: @user.id)
    id   = data.delete(:id).to_s
    @item, failed = upload_update(id, data)
    fail(__method__, failed) if failed.present?
    post_response(:ok, @item, redirect: upload_index_path)
  rescue SubmitError => error
    post_response(:conflict, error) # TODO: ?
  rescue => error
    post_response(error)
  end

  # == GET /upload/delete/:id[?force=true]
  # Initiate removal of an existing EMMA entry along with its associated file.
  #
  # If :id is "SELECT" then a menu of deletable items is presented.
  #
  # Use :force to attempt to remove an item from the EMMA Unified Search index
  # even if a database record was not found.
  #
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  #
  # @see Upload#expand_ids
  # @see UploadConcern#get_record
  # @see #destroy
  #
  def delete
    __debug_route
    ids = Upload.expand_ids(@item_id).presence or fail(:file_id)
    ids.clear if show_menu?(ids)
    @list = ids.map { |id| get_record(id, no_raise: force_delete) || id }
  rescue => error
    flash_now_failure(error)
  end

  # == DELETE /upload/:id[?force=true]
  # == DELETE /upload/ITEM_SPEC[?force=true]
  # Finalize removal of an existing EMMA entry.
  #
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  #
  # @see UploadConcern#upload_destroy
  #
  #--
  # noinspection RubyScope
  #++
  def destroy
    __debug_route
    back = delete_select_upload_path
    succeeded, failed = bulk_upload_destroy(@item_id)
    fail(__method__, failed) if failed.present?
    fail(:file_id)           if succeeded.blank?
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

  # == GET /download/:id
  # Download the file associated with an EMMA submission.
  #
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  #
  # @see UploadConcern#get_record
  # @see Upload#download_url.
  #
  def download
    __debug_route
    @item = get_record(@item_id)
    @link = @item.download_url
    respond_to do |format|
      format.html { redirect_to(@link) }
      format.json { render_json download_values }
      format.xml  { render_xml  download_values }
    end
  end

  # == GET /retrieval?url=URL
  # Retrieve a file from a member repository.
  #
  def retrieval
    __debug_route
    if ia_link?(@url)
      render_ia_download(@url)
    else
      Log.error { "/retrieval can't handle #{@url.inspect}"}
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /upload/bulk
  # TODO: ???
  #
  def bulk_index
    __debug_route
  rescue => error
    flash_now_failure(error)
  end

  # == GET /upload/bulk_new[?source=FILE&batch=true|SIZE&prefix=STRING]
  # Display a form prompting for a bulk upload file in either CSV or JSON
  # format containing an entry for each entry to submit.
  #
  # @see #bulk_create
  #
  def bulk_new
    __debug_route
  rescue => error
    flash_now_failure(error)
  end

  # == POST /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  # Create the specified Upload entries, download and store the associated
  # files, and post the new entries to the Federated Ingest API.
  #
  # @raise [Net::HTTPConflict]
  #
  # @see UploadConcern#bulk_upload_create
  #
  def bulk_create
    __debug_route
    __debug_request
    data = upload_bulk_post_parameters.presence or fail(__method__)
    opt  = { base_url: request.base_url, user: @user }
    succeeded, failed = bulk_upload_create(data, **opt)
    fail(__method__, failed) if failed.present?
    post_response(:ok, succeeded, xhr: false)
  rescue SubmitError => error
    post_response(:conflict, error, xhr: false) # TODO: ?
  rescue => error
    post_response(error, xhr: false)
  end

  # == GET /upload/bulk_edit[?source=FILE&batch=true|SIZE&prefix=STRING]
  # Display a form prompting for a bulk upload file in either CSV or JSON
  # format containing an entry for each entry to change.
  #
  # @see UploadConcern#bulk_upload_update
  #
  def bulk_edit
    __debug_route
  rescue => error
    flash_now_failure(error)
  end

  # == PUT /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  # Modify or create the specified Upload entries, download and store the
  # associated files (if changed), and post the new/modified entries to the
  # Federated Ingest API.
  #
  # @raise [Net::HTTPConflict]
  #
  # @see UploadConcern#bulk_upload_update
  #
  def bulk_update
    __debug_route
    __debug_request
    data = upload_bulk_post_parameters.presence or fail(__method__)
    opt  = { base_url: request.base_url, user: @user }
    succeeded, failed = bulk_upload_update(data, **opt)
    fail(__method__, failed) if failed.present?
    post_response(:ok, succeeded, xhr: false)
  rescue SubmitError => error
    post_response(:conflict, error, xhr: false) # TODO: ?
  rescue => error
    post_response(error, xhr: false)
  end

  # == GET /upload/bulk_delete[?force=false]
  # Select
  #
  # @raise [Net::HTTPConflict]
  #
  # @see UploadConcern#bulk_upload_destroy
  #
  def bulk_delete
    __debug_route
  rescue => error
    flash_now_failure(error)
  end

  # == DELETE /upload/bulk[?force=true]
  #
  # @raise [Net::HTTPConflict]
  #
  # @see UploadConcern#bulk_upload_destroy
  #
  def bulk_destroy
    __debug_route
    __debug_request
    data = upload_bulk_post_parameters.presence or fail(__method__)
    succeeded, failed = bulk_upload_destroy(data)
    fail(__method__, failed) if failed.present?
    post_response(:found, succeeded, xhr: false)
  rescue SubmitError => error
    post_response(:conflict, error, xhr: false) # TODO: ?
  rescue => error
    post_response(error, xhr: false)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether URL parameters indicate that a menu should be shown rather
  # than operating on an explicit set of identifiers.
  #
  # @param [String, Array<String>] id_params  Default: `@item_id`.
  #
  def show_menu?(id_params = nil)
    Array.wrap(id_params || @item_id).include?('SELECT')
  end

  # Display the failure on the screen -- immediately if modal, or after a
  # redirect otherwise.
  #
  # @param [Exception] error
  # @param [String]    fallback_location    Redirect fallback if not modal.
  #
  def show_search_failure(error, fallback_location)
    if modal?
      flash_now_failure(error)
    else
      flash_failure(error)
      redirect_back(fallback_location: fallback_location)
    end
  end

  # Get item data from the production service.
  #
  # @param [String] rid               Repository ID of the item.
  # @param [String] host              Base URL of production service.
  #
  # @return [Upload]                  Object created from received data.
  # @return [nil]                     Bad data and/or no object created.
  #
  def proxy_get_record(rid, host)
    data = Faraday.get("#{host}/upload/#{rid}.json").body.presence
    data &&= json_parse(data)
    data &&= data[:entry]
    new_record(data) if data.present?
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Extract the best-match URL parameter which represents an item identifier.
  #
  # The @item_id member variable contains the original item specification, if
  # one was provided, and not the array of IDs represented by it.
  #
  # @return [String]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :selected, :repository_id found.
  #
  def set_item_id
    # noinspection RubyYardReturnMatch
    @item_id ||=
      if (id = params[:selected] || params[:repository_id])
        params[:id] = id if params.key?(:id)
        id
      else
        params[:id]
      end
  end

  # If the :show endpoint is given an :id which is actually a specification for
  # multiple items then there is a redirect to :index.
  #
  def index_redirect
    redirect_to action: :index, id: @item_id if @item_id.match?(/[^[:alnum:]]/)
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

  # Response values for de-serializing download information to JSON or XML.
  #
  # @param [String] url
  #
  # @return [Hash{Symbol=>String}]
  #
  def download_values(url = @link)
    { url: url}
  end

end

__loading_end(__FILE__)
