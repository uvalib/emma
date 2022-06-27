# app/controllers/entry_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/entry" requests.
#
# @see EntryDecorator
# @see EntriesDecorator
# @see file:app/views/entry/**
#
class EntryController < ApplicationController

  include UserConcern
  include ParamsConcern
  include OptionsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include SerializationConcern
  include AwsConcern
  include BookshareConcern
  include IngestConcern
  include IaDownloadConcern
  include EntryConcern

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
  before_action :authenticate_admin!, only:   %i[bulk_reindex]
  before_action :authenticate_user!,  except: %i[bulk_reindex show]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :set_identifiers, only: %i[
    index         show
    create        edit          update        delete        destroy
    cancel        check         endpoint      download      bulk_reindex
  ]
  before_action :set_ingest_engine, only: %i[
    index         new           edit          delete
    bulk_index    bulk_new      bulk_edit     bulk_delete   bulk_reindex
  ]
  before_action :index_redirect,        only: %i[show]
  before_action :set_bs_member,         only: %i[retrieval]
  before_action :set_item_download_url, only: %i[retrieval]
  before_action :resolve_sort,          only: %i[admin]

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
  # @return [Array<Entry>]
  # @return [Array<String>]
  # @return [nil]
  #
  attr_reader :list

  # API results for :show.
  #
  # @return [Entry, nil]
  #
  attr_reader :item

  # For the :admin endpoint.
  #
  # @return [Hash{String=>Array<Aws::S3::Object>}]
  #
  attr_reader :s3_object_table
  helper_attr :s3_object_table

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /entry[?id=(:id|SID|RANGE_LIST)]
  # == GET /entry[?selected=(:id|SID|RANGE_LIST)]
  # == GET /entry[?group=WORKFLOW_GROUP]
  #
  # Display the current user's EMMA entries.
  #
  # If an item specification is given by one of EntryConcern#IDENTIFIER_PARAMS
  # then the results will be limited to the matching entries.
  # NOTE: Currently this is not limited only to the current user's entries.
  #
  # @see #entry_index_path            Route helper
  # @see EntryConcern#find_or_match_entries
  #
  def index
    __debug_route
    @page  = pagination_setup
    opt    = @page.initial_parameters
    opt.except!(:group, :groups) # TODO: upload -> entry
    all    = opt[:group].nil? || (opt[:group].to_sym == :all)
    result = find_or_match_entries(groups: all, **opt)
    @page.finalize(result, **opt)
    @list  = result[:list]
    result = find_or_match_entries(groups: :only, **opt) if opt.delete(:group)
    @group_counts = result[:groups]
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :entry) }
    end
  rescue Record::SubmitError => error
    show_search_failure(error)
  rescue => error
    show_search_failure(error, root_path)
    re_raise_if_internal_exception(error)
  end

  # == GET /entry/show/(:id|SID)
  #
  # Display a single entry.
  #
  # @see #show_entry_path             Route helper
  # @see EntryConcern#get_entry
  #
  def show
    __debug_route
    @item = get_entry
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue Record::NotFound, ActiveRecord::RecordNotFound => error
    # As a convenience (for HTML only), if an index item is actually on another
    # instance, fetch it from there to avoid a potentially confusing result.
    if request.format.html?
      # noinspection RubyMismatchedReturnType
      [STAGING_BASE_URL, PRODUCTION_BASE_URL].find do |base_url|
        next if base_url.start_with?(request.base_url)
        @host = base_url
        @item = proxy_get_record(@identifier, @host)
      end
    end
    show_search_failure(error) if @item.blank?
  rescue => error
    show_search_failure(error)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # == GET /entry/new
  #
  # Initiate creation of a new EMMA entry by displaying the form which prompts
  # to upload a file and collects metadata for the new entry.
  #
  # TODO: verify this:
  # On the initial visit to the page, @entry_id should be *nil*.  On subsequent
  # visits (due to "Cancel" returning to this same page), @entry_id will be
  # included in order to reuse the Entry record that was created at that time.
  #
  # @see #new_entry_path              Route helper
  # @see EntryConcern#new_entry
  # @see EntryController#create
  # @see file:app/assets/javascripts/feature/model-form.js
  #
  def new
    __debug_route
    @item = new_entry
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # == POST  /entry/create
  # == PUT   /entry/create
  # == PATCH /entry/create
  #
  # Invoked from the handler for the Uppy 'upload-success' event to finalize
  # the creation of a new EMMA entry.
  #
  # @see #create_entry_path           Route helper
  # @see EntryConcern#create_entry
  # @see EntryController#new
  #
  def create
    __debug_route
    @item = create_entry
    post_response(:ok, @item, redirect: entry_index_path)
  rescue => error
    post_response(error)
    re_raise_if_internal_exception(error)
  end

  # == GET /entry/edit/:id
  # == GET /entry/edit/SELECT
  # == GET /entry/edit_select
  #
  # Initiate modification of an existing EMMA entry by prompting for metadata
  # changes and/or upload of a replacement file.
  #
  # If :id is "SELECT" then a menu of editable items is presented.
  #
  # @see #edit_entry_path             Route helper
  # @see #edit_select_entry_path      Route helper
  # @see EntryConcern#edit_entry
  # @see EntryController#update
  # @see file:app/assets/javascripts/feature/model-form.js
  #
  def edit
    __debug_route
    @item = (edit_entry unless show_menu?)
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # == PUT   /entry/update/:id
  # == PATCH /entry/update/:id
  #
  # Finalize modification of an existing EMMA entry.
  #
  # @see #update_entry_path           Route helper
  # @see EntryConcern#update_entry
  # @see EntryController#edit
  #
  def update
    __debug_route
    __debug_request
    @item = update_entry
    post_response(:ok, @item, redirect: entry_index_path)
  rescue => error
    post_response(error)
    re_raise_if_internal_exception(error)
  end

  # == GET /entry/delete/:id[?force=true&truncate=true&emergency=true]
  # == GET /entry/delete/SID[?...]
  # == GET /entry/delete/RANGE_LIST[?...]
  # == GET /entry/delete/SELECT[?...]
  # == GET /entry/delete_select
  #
  # Initiate removal of an existing EMMA entry along with its associated file.
  #
  # If :id is "SELECT" then a menu of deletable items is presented.
  #
  # Use :force to attempt to remove an item from the EMMA Unified Search index
  # even if a database record was not found.
  #
  # @see #delete_entry_path           Route helper
  # @see #delete_select_entry_path    Route helper
  # @see EntryConcern#delete_entry
  # @see EntryController#destroy
  #
  def delete
    __debug_route
    @list = []
    result = delete_entry || {}
    @list = result[:list] || []
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # == DELETE /entry/destroy/:id[?force=true&truncate=true&emergency=true]
  # == DELETE /entry/destroy/SID[?...]
  # == DELETE /entry/destroy/RANGE_LIST[?...]
  #
  # Finalize removal of an existing EMMA entry.
  #
  # @see #destroy_entry_path          Route helper
  # @see EntryConcern#destroy_entry
  # @see EntryController#delete
  #
  def destroy
    __debug_route
    back  = delete_select_entry_path
    @list = destroy_entry
    post_response(:found, @list, redirect: back)
  rescue => error
    # noinspection RubyScope
    post_response(error, redirect: back)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  public

  # == GET /entry/bulk
  #
  # Currently a non-functional placeholder.
  #
  # @see #bulk_entry_index_path       Route helper
  #
  def bulk_index
    __debug_route
    # TODO: bulk_index ???
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # == GET /entry/bulk_new[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Display a form prompting for a bulk operation manifest (either CSV or JSON)
  # containing an row/element for each entry to submit.
  #
  # @see #bulk_new_entry_path         Route helper
  # @see EntryConcern#bulk_new_entries
  # @see EntryController#bulk_create
  #
  def bulk_new
    __debug_route
    bulk_new_entries
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # == POST /entry/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Create the specified Entry records, download and store the associated
  # files, and post the new entries to the Federated Ingest API.
  #
  # @see #bulk_create_entry_path      Route helper
  # @see EntryConcern#bulk_create_entries
  # @see EntryController#bulk_new
  #
  def bulk_create
    __debug_route
    __debug_request
    @list = bulk_create_entries
    post_response(:ok, @list, xhr: false)
  rescue => error
    post_response(error, xhr: false)
    re_raise_if_internal_exception(error)
  end

  # == GET /entry/bulk_edit[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Display a form prompting for a bulk operation manifest (either CSV or JSON)
  # containing an row/element for each entry to change.
  #
  # @see #bulk_edit_entry_path        Route helper
  # @see EntryConcern#bulk_edit_entries
  # @see EntryController#bulk_update
  #
  def bulk_edit
    __debug_route
    @list = bulk_edit_entries
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # == PUT   /entry/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  # == PATCH /entry/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Modify or create the specified Entry records, download and store the
  # associated files (if changed), and post the new/modified entries to the
  # Federated Ingest API.
  #
  # @see #bulk_update_entry_path      Route helper
  # @see EntryConcern#bulk_update_entries
  # @see EntryController#bulk_edit
  #
  def bulk_update
    __debug_route
    __debug_request
    @list = bulk_update_entries
    post_response(:ok, @list, xhr: false)
  rescue => error
    post_response(error, xhr: false)
    re_raise_if_internal_exception(error)
  end

  # == GET /entry/bulk_delete[?force=false]
  #
  # Specify entries to delete by :id, SID, or RANGE_LIST.
  #
  # @see #bulk_delete_entry_path      Route helper
  # @see EntryConcern#bulk_delete_entries
  # @see EntryController#bulk_destroy
  #
  def bulk_delete
    __debug_route
    @list = bulk_delete_entries
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # == DELETE /entry/bulk[?force=true]
  #
  # @see #bulk_destroy_entry_path     Route helper
  # @see EntryConcern#bulk_destroy_entries
  # @see EntryController#bulk_delete
  #
  def bulk_destroy
    __debug_route
    __debug_request
    @list = bulk_destroy_entries
    post_response(:found, @list)
  rescue => error
    post_response(error, xhr: false)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # == POST /entry/renew
  #
  # Invoked to resupply field values to a form generated for "/new".
  #
  # @see #renew_entry_path                                  Route helper
  # @see EntryConcern#renew_entry
  # @see file:app/assets/javascripts/feature/model-form.js  *refreshRecord()*
  #
  def renew
    __debug_route
    @item = renew_entry
    respond_to do |format|
      format.html
      format.json { render json: @item }
      format.xml  { render xml:  @item }
    end
  rescue => error
    post_response(error)
    re_raise_if_internal_exception(error)
  end

  # == POST /entry/reedit?id=:id
  #
  # Invoked to resupply field values to a form generated for "/edit".
  #
  # @see #reedit_entry_path                                 Route helper
  # @see EntryConcern#reedit_entry
  # @see file:app/assets/javascripts/feature/model-form.js  *refreshRecord()*
  #
  def reedit
    __debug_route
    @item = reedit_entry
    respond_to do |format|
      format.html
      format.json { render json: @item }
      format.xml  { render xml:  @item }
    end
  rescue => error
    post_response(error)
    re_raise_if_internal_exception(error)
  end

  # == GET  /entry/cancel?id=:id[&redirect=URL][&reset=bool][&fields=...]
  # == POST /entry/cancel?id=:id[&fields=...]
  #
  # Invoked to cancel the current submission form instead of submitting.
  #
  # * If invoked via :get, a :redirect is expected.
  # * If invoked via :post, only a status is returned.
  #
  # Either way, the identified Entry record is deleted if it was in the
  # :create phase.  If it was in the :edit phase, its fields are reset
  #
  # @see #cancel_entry_path                                 Route helper
  # @see EntryConcern#cancel_entry
  # @see file:app/assets/javascripts/feature/model-form.js  *cancelForm()*
  #
  def cancel
    __debug_route
    @item = nil # cancel_entry # TODO: cancel_entry for Entry/Phase/Action ?
    if request.get?
      # noinspection RubyMismatchedArgumentType
      redirect_to(params[:redirect] || entry_index_path)
    else
      post_response(:ok)
    end
  rescue => error
    if request.get?
      flash_now_failure(error)
    else
      post_response(error)
    end
    re_raise_if_internal_exception(error)
  end

  # == GET /entry/check/:id
  # == GET /entry/check/SID
  #
  # Invoked to determine whether the workflow state of the indicated item can
  # be advanced.
  #
  # @see #check_entry_path            Route helper
  # @see EntryConcern#check_entry
  #
  def check
    __debug_route
    @list = check_entry
    data  = { messages: @list }
    respond_to do |format|
      format.html
      format.json { render_json data }
      format.xml  { render_xml  data }
    end
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == POST /entry/endpoint
  #
  # Invoked from 'Uppy.XHRUpload'.
  #
  # @see #entries_path                Route helper
  # @see EntryConcern#upload_file
  # @see file:app/assets/javascripts/feature/model-form.js
  #
  def endpoint
    __debug_route
    __debug_request
    stat, hdrs, body = upload_file
    self.status = stat        if stat.present?
    self.headers.merge!(hdrs) if hdrs.present?
    self.response_body = body if body.present?
  rescue Record::SubmitError => error
    post_response(:conflict, error, xhr: true)
  rescue => error
    post_response(error, xhr: true)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /download/:id
  #
  # Download the file associated with an EMMA submission.
  #
  # @see #file_download_path          Route helper
  # @see EntryConcern#get_entry
  # @see Record::Uploadable#download_url
  #
  def download
    __debug_route
    @item = get_entry
    link  = @item.download_url
    respond_to do |format|
      format.html { redirect_to link }
      format.json { render_json download_values(link) }
      format.xml  { render_xml  download_values(link) }
    end
  rescue => error
    post_response(error, xhr: true)
    re_raise_if_internal_exception(error)
  end

  # == GET /retrieval?url=URL[&member=BS_ACCOUNT_ID]
  #
  # Retrieve a file from a member repository.
  #
  # @raise [ExecError] @see IaDownloadConcern#ia_download_response
  #
  # @see #retrieval_path              Route helper
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def retrieval
    __debug_route
    if ia_link?(item_download_url)
      ia_download_response(item_download_url)
    elsif bs_link?(item_download_url)
      redirect_to bs_retrieval_path(url: item_download_url, forUser: bs_member)
    else
      Log.error { "/retrieval can't handle #{item_download_url.inspect}" }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /entry/admin[?(deploy|deployment)=('production'|'staging')]
  # == GET /entry/admin[?(repo|repository)=('emma'|'ia')]
  #
  # Entry submission administration.
  #
  # @see #admin_entry_path            Route helper
  # @see AwsConcern#get_object_table
  #
  def admin
    __debug_route
    @s3_object_table = get_s3_object_table(**url_parameters)
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /entry/bulk_reindex?size=PAGE_SIZE[&id=(:id|SID|RANGE_LIST)]
  #
  # Cause completed submission records to be re-indexed.
  #
  # @see #bulk_reindex_entry_path     Route helper
  # @see EntryConcern#reindex_record
  #
  def bulk_reindex
    __debug_route
    opt = request_parameters.slice(:size).merge!(meth: __method__)
    @list, failed = reindex_submissions(*@identifier, **opt)
    failure(:invalid, failed.uniq) if failed.present?
  rescue => error
    flash_now_failure(error)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /phases
  #
  # List Phase records # TODO: probably temporary
  #
  def phases
    __debug_route
    @list = Phase.all.order(:id).to_a
  end

  # == GET /actions
  #
  # List Action records # TODO: probably temporary
  #
  def actions
    __debug_route
    @list = Action.all.order(:id).to_a
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether URL parameters require that a menu should be shown rather
  # than operating on an explicit set of identifiers.
  #
  # @param [String, Array<String>, nil] id_params  Default: `@identifier`.
  #
  def show_menu?(id_params = nil)
    Array.wrap(id_params || @identifier).include?('SELECT')
  end

  # Display the failure on the screen -- immediately if modal, or after a
  # redirect otherwise.
  #
  # @param [Exception] error
  # @param [String]    fallback   Redirect fallback (def.: #entry_index_path).
  # @param [Symbol]    meth       Calling method.
  #
  # @return [void]
  #
  def show_search_failure(error, fallback = nil, meth: nil)
    meth ||= calling_method
    if modal?
      flash_now_failure(error, meth: meth)
    else
      flash_failure(error, meth: meth)
      redirect_back(fallback_location: (fallback || entry_index_path))
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # If the :show endpoint is given an :id which is actually a specification for
  # multiple items then there is a redirect to :index.
  #
  # @return [void]
  #
  def index_redirect
    return unless @identifier && @identifier.match?(/[^[:alnum:]]/)
    redirect_to action: :index, selected: @identifier
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Any]  list
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :entries)
    super(list, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Model, Hash] item
  # @param [Hash]        opt
  #
  # @return [Hash{Symbol=>Any}]
  #
  def show_values(item = @item, **opt)
    item = item.is_a?(ActiveRecord) ? item.attributes.symbolize_keys : item.dup
    data = item.extract!(:file_data).first&.last
    item[:file_data] = safe_json_parse(data)
    super(item, **opt)
  end

  # Response values for de-serializing download information to JSON or XML.
  #
  # @param [String, nil] url
  #
  # @return [Hash{Symbol=>String,nil}]
  #
  def download_values(url)
    { url: url }
  end

end

__loading_end(__FILE__)
