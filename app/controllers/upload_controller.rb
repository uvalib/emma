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

  # before_action :update_user
  # before_action :authenticate_user!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  # authorize_resource # TODO: upload authorization
  skip_authorization_check # TODO: temporary - remove

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  respond_to :html
  respond_to :json, :xml, except: %i[edit] # TODO: ???

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /upload
  # Display the current user's uploads.
  #
  def index
    __debug_route('UPLOAD')
    opt   = pagination_setup
    @list = @user_id ? Upload.where(user_id: @user_id) : Upload.all
    self.page_items  = @list
    self.total_items = @list.size
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /upload/:id
  # Display a single upload.
  #
  def show
    __debug_route('UPLOAD')
    id = params[:id]        or fail(:file_id)
    @item = Upload.find(id) or fail(:find, id)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /upload/new[?modal=true]
  # Initiate creation of a new EMMA entry by prompting to upload a file.
  #
  def new
    __debug_route('UPLOAD')
    @item = Upload.new
    respond_with(@item)

  rescue => error
    flash_now_failure(error)

  end

  # == POST /upload
  # Invoked from the handler for the Uppy 'upload-success' event to finalize
  # the creation of a new EMMA entry.
  #
  # @see app/assets/javascripts/feature/file-upload.js
  #
  def create
    __debug_route('UPLOAD')
    data  = upload_post_parameters
    @item = Upload.new(data) or fail(__method__)
    @item.save
    @item.errors.blank?      or fail(@item.errors)
    post_response(:ok, @item.filename, redirect: upload_index_path)

  rescue SubmitError => error
    post_response(:conflict, error) # TODO: ?

  rescue => error
    post_response(error)

  end

  # == GET /upload/:id/edit
  # == GET /upload/:repositoryId/edit
  # Initiate modification of an existing EMMA entry by prompting for metadata
  # changes and/or upload of a replacement file.
  #
  def edit
    __debug_route('UPLOAD')
    id = params[:selected] || params[:id]
    case id
      when nil      then fail(:file_id)
      when 'SELECT' then @item = nil
      else               @item = Upload.find(id) or fail(:find, id)
    end

  rescue => error
    flash_now_failure(error)

  end

  # == PUT   /upload/:id
  # == PUT   /upload/:repositoryId
  # == PATCH /upload/:id
  # == PATCH /upload/:repositoryId
  # Finalize modification of an existing EMMA entry.
  #
  def update
    __debug_route('UPLOAD')
    __debug_request
    data = upload_post_parameters
    id   = data.delete(:id) or fail(:file_id)
    @item = Upload.find(id) or fail(:find, id)
    @item.update(data)
    @item.errors.blank?     or fail(@item.errors)
    post_response(:ok, @item.filename, redirect: upload_index_path)

  rescue SubmitError => error
    post_response(:conflict, error) # TODO: ?

  rescue => error
    post_response(error)

  end

  # == GET /upload/:id/delete
  # == GET /upload/:repositoryId/delete
  # Initiate removal of an existing EMMA entry along with its associated file.
  #
  def delete
    __debug_route('UPLOAD')
    id = params[:selected] || params[:id]
    case id
      when nil      then fail(:file_id)
      when 'SELECT' then @item = nil
      else               @item = Upload.find(id) or fail(:find, id)
    end

  rescue => error
    flash_now_failure(error)

  end

  # == DELETE /upload/:id
  # == DELETE /upload/:repositoryId
  # Finalize removal of an existing EMMA entry.
  #
  # noinspection RubyScope
  def destroy
    __debug_route('UPLOAD')
    back = delete_select_upload_path
    id   = params[:id] or fail(:file_id)
    names =
      if id.include?(',')
        id.split(/\s*,\s*/).map { |n| destroy_upload(Upload.find(n)) }.compact
      else
        @item = Upload.find(id) or fail(:find, id)
        destroy_upload(@item)
      end
    post_response(:found, names, redirect: back)

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
  # @see app/assets/javascripts/feature/file-upload.js
  #
  def endpoint
    __debug_route('UPLOAD')
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
