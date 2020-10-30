# app/controllers/concerns/upload_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

# UploadConcern
#
module UploadConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'UploadConcern')

    # Methods that are exposed for use in views.
    helper_method *UploadWorkflow::Properties.public_instance_methods(false)

  end

  include Emma::Csv
  include Emma::Json
  include ParamsHelper
  include UploadWorkflow::Properties

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  MIME_REGISTRATION =
    FileNaming.format_classes.values.each(&:register_mime_types)

  # ===========================================================================
  # :section: Parameters
  # ===========================================================================

  public

  # POST/PUT/PATCH parameters from the upload form that are not relevant to the
  # create/update of an Upload instance.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_UPLOAD_FORM_PARAMETERS = %i[limit field-group cancel].sort.freeze

  # ===========================================================================
  # :section: Parameters
  # ===========================================================================

  public

  # URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def upload_params
    @upload_params ||= get_upload_params
  end

  # Get URL parameters relevant to the current operation.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>*}]
  #
  def get_upload_params(p = nil)
    prm = url_parameters(p)
    prm.except!(*IGNORED_UPLOAD_FORM_PARAMETERS)
    prm.deep_symbolize_keys!
    reject_blanks(prm)
  end

  # Extract POST parameters that are usable for creating/updating an Upload
  # instance.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>*}]
  #
  # == Implementation Notes
  # The value `params[:upload][:emma_data]` is ignored because it reports the
  # original metadata values that were supplied to the edit form.  The value
  # `params[:upload][:file]` is ignored if it is blank or is the JSON
  # representation of an empty object ("{}") -- this indicates an editing
  # submission where metadata is being changed but the uploaded file is not
  # being replaced.
  #
  def upload_post_parameters(p = nil)
    prm  = p ? get_upload_params(p) : upload_params
    data = prm.delete(:upload) || {}
    file = data[:file]
    prm[:file_data] = file unless file.blank? || (file == '{}')
    prm[:base_url]  = request.base_url
    @upload_params  = reject_blanks(prm)
  end

  # Extract POST parameters and data for bulk operations.
  #
  # @param [ActionController::Parameters, Hash] p   Default: `#url_parameters`.
  # @param [ActionDispatch::Request]            req Default: `#request`.
  #
  # @return [Array<Hash>]
  #
  def upload_bulk_post_parameters(p = nil, req = nil)
    prm = p ? get_upload_params(p) : upload_params
    src = prm[:src] || prm[:source]
    opt = src ? { src: src } : { data: (req || request) }
    Array.wrap(fetch_data(**opt)).map(&:symbolize_keys)
  end

  # workflow_parameters
  #
  # @return [Hash]
  #
  def workflow_parameters
    upload_post_parameters.tap { |result|
      result[:id]        = @db_id    if @db_id
      result[:user_id]   = @user.id  if @user
    }.except(:selected)
  end

  # ===========================================================================
  # :section: Parameters
  # ===========================================================================

  protected

  # Remote or locally-provided data.
  #
  # @param [Hash] opt
  #
  # @option opt [String]       :src   URI or path to file containing the data.
  # @option opt [String, Hash] :data  Literal data.
  #
  # @raise [StandardError]            If both *src* and *data* are present.
  #
  # @return [nil]                     If both *src* and *data* are missing.
  # @return [Hash]
  # @return [Array<Hash>]
  #
  def fetch_data(**opt)
    __debug_args("UPLOAD #{__method__}", binding)
    src  = opt[:src].presence
    data = opt[:data].presence
    if data
      raise "#{__method__}: both :src and :data were given" if src
      name = nil
    elsif src.is_a?(ActionDispatch::Http::UploadedFile)
      name = src.original_filename
      data = src
    elsif src
      name = src
      data =
        case name
          when /^https?:/ then Faraday.get(src)   # Remote file URI.
          when /\.csv$/   then src                # Local CSV file path.
          else                 File.read(src)     # Local JSON file path.
        end
    else
      return Log.warn { "#{__method__}: neither :data nor :src given" }
    end
    # noinspection RubyYardReturnMatch
    case name.to_s.downcase.split('.').last
      when 'json' then json_parse(data)
      when 'csv'  then csv_parse(data)
      else             json_parse(data) || csv_parse(data)
    end
  end

  # ===========================================================================
  # :section: Identifiers
  # ===========================================================================

  public

  # URL parameters associated with item/entry identification.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = %i[id selected submission_id].freeze

  # Extract the best-match URL parameter which represents an item identifier.
  #
  # The @identifier member variable contains the original item specification,
  # if one was provided, and not the array of IDs represented by it.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [String]                  Value of @identifier.
  # @return [nil]                     No param from #IDENTIFIER_PARAMS found.
  #
  def set_identifiers(p = nil)
    prm = url_parameters(p)
    id, sel, sid = prm.values_at(*IDENTIFIER_PARAMS).map(&:presence)
    @db_id = (sel.to_i if digits_only?(sel)) || (id.to_i if digits_only?(id))
    @identifier = sel || sid || id
  end

  # ===========================================================================
  # :section: Records
  # ===========================================================================

  public

  # Locate and filter records.
  #
  # @param [Array<String,Array>] items  Default: `@identifier`.
  # @param [Hash]                opt    Default: `#upload_params`.
  #
  # @return [Array<Upload>]
  #
  # @see UploadController#match_records
  #
  def find_or_match_records(*items, **opt)
    items = items.flatten.compact
    items << @identifier if items.blank? && @identifier.present?
    if items.present?
      Upload.get_records(*items)
    else
      opt = upload_params if opt.blank?
      match_records(**opt)
    end
  end

  # Locate and filter records.
  #
  # @param [Array<String,Array>] items
  # @param [Hash]                opt    Database WHERE predicates.
  #
  # @return [Array<Upload>]
  #
  # @see Upload#get_records
  #
  def match_records(*items, **opt)
    # Disallow experimental database WHERE predicates unless privileged.
    admin = true # TODO: delete
    #admin = can?(:manage, Upload) # TODO: restore
    opt.slice!(:user, :user_id, :state) unless admin

    # Select records for the current user unless a different user has been
    # specified (or all records if specified as '*', 'all', or 'false').
    u = opt.delete(:user)
    u = opt.delete(:user_id) || u || @user
    if u.is_a?(String) || u.is_a?(Symbol)
      u = u.to_s.strip.downcase
      u = 0      if %w(* 0 all false).include?(u)
      u = u.to_i if digits_only?(u)
    end
    # noinspection RubyCaseWithoutElseBlockInspection
    case u
      when 0       then u = nil
      when Integer then u = User.find(u)
      when String  then u = User.find_by(email: u)
    end
    if u.is_a?(User)
      opt[:user_id]   = u.id  if u.id.present?
      opt[:edit_user] = u.uid if u.uid.present?
    end

    # Limit records to those in the given state (or records with an empty state
    # field if specified as 'nil', 'empty', or 'missing').
    if (s = opt.delete(:state).to_s.strip.downcase).present?
      if %w(empty false missing nil none null).include?(s)
        opt[:state] = nil
      else
        opt[:state] = s
        opt[:edit_state] ||= s
      end
    end

    Upload.get_records(*items, **opt)
  end

  # Return with the specified record or *nil* if one could not be found.
  #
  # @param [String, Hash, Upload] id
  #
  # @raise [StandardError]            If *item* not found.
  #
  # @return [Upload, nil]
  #
  # @see Upload#get_record
  #
  def get_record(id)
    if (result = Upload.get_record(id))
      result
    elsif Upload.id_term(id).values.first.blank?
      failure(:file_id)
    else
      Log.error { "#{__method__}: #{id}: non-existent record" }
      failure(:find, id)
    end
  end

  # Get item data from the production service.
  #
  # @param [String] sid               Submission ID of the item.
  # @param [String] host              Base URL of production service.
  #
  # @return [Upload]                  Object created from received data.
  # @return [nil]                     Bad data and/or no object created.
  #
  def proxy_get_record(sid, host)
    data = sid && Faraday.get("#{host}/upload/#{sid}.json").body.presence
    data &&= json_parse(data)
    data &&= data[:entry]
    Upload.new(data) if data.present?
  end

  # ===========================================================================
  # :section: Workflow
  # ===========================================================================

  public

  # Gather information to create an upload workflow instance.
  #
  # @param [String, Integer, :unset, nil] rec
  # @param [Hash, String, :unset, nil]    data
  # @param [Hash]                         opt   To workflow initializer except:
  #
  # @option opt [Symbol] :from        Default: `#calling_method`.
  # @option opt [Symbol] :event
  #
  # @return [*]                       @see UploadWorkflow::Single#results
  #
  # @see UploadWorkflow::Single#generate
  #
  def wf_single(rec: nil, data: nil, **opt)
    from  = (opt.delete(:from) || calling_method)&.to_sym
    event = opt.delete(:event)&.to_s&.delete_suffix('!')&.to_sym
    raise "#{__method__}: missing :from" unless from
    raise "#{from}: missing :event"      unless event
    rec  = (rec  || @db_id || @identifier unless rec  == :unset)
    data = (data || workflow_parameters unless data == :unset)
    opt[:variant] ||= event if UploadWorkflow::Single.variant?(event)
    opt[:user]    ||= @user
    opt[:params]  ||= workflow_parameters
    opt[:no_sim]    = true if UploadWorkflow::Single::SIMULATION # TODO: remove
    @workflow = UploadWorkflow::Single.generate(rec, **opt)
    @workflow.send("#{event}!", data) or failure(from, @workflow.failed)
    @workflow.results
  end

  # Determine whether the workflow state of the indicated item can be advanced.
  #
  # @param [String, Integer, nil] rec
  # @param [Hash]                 opt
  #
  # @return [Array<String>]       @see UploadWorkflow::Single#wf_check_status
  #
  # @see UploadWorkflow::Single#check_status
  #
  def wf_single_check(rec: nil, **opt)
    from           = (opt.delete(:from) || calling_method)&.to_sym
    rec          ||= @db_id || @identifier
    opt[:user]   ||= @user
    opt[:params] ||= workflow_parameters
    opt[:no_sim]   = true if UploadWorkflow::Single::SIMULATION # TODO: remove
    opt[:html]     = params[:format].blank? || (params[:format] == 'html')
    # noinspection RubyYardParamTypeMatch
    @workflow = UploadWorkflow::Single.check_status(rec, **opt)
    # noinspection RubyYardReturnMatch
    @workflow.results
  end

  # Gather information to create a bulk upload workflow instance.
  #
  # @param [Array, :unset, nil] rec
  # @param [Array, :unset, nil] data
  # @param [Hash]               opt   To workflow initializer except:
  #
  # @option opt [Symbol] :from        Default: `#calling_method`.
  # @option opt [Symbol] :event
  #
  # @return [Array<Upload,String>]    @see UploadWorkflow::Bulk#results
  #
  # @see UploadWorkflow::Bulk#generate
  #
  def wf_bulk(rec: nil, data: nil, **opt)
    from  = (opt.delete(:from) || calling_method)&.to_sym
    event = opt.delete(:event)&.to_s&.delete_suffix('!')
    raise "#{__method__}: missing :from" unless from
    raise "#{from}: missing :event"      unless event
    rec   = (rec == :unset) ? [] : (rec || []) # TODO: transaction record?
    data  = [] if data == :unset
    unless data
      data = upload_bulk_post_parameters or failure(from)
      data << { base_url: request.base_url }
      opt[:control] ||= params[:src] || params[:source]
    end
    opt[:variant] ||= event if UploadWorkflow::Bulk.variant?(event)
    opt[:user]    ||= @user
    opt[:params]  ||= workflow_parameters
    opt[:no_sim]    = true if UploadWorkflow::Bulk::SIMULATION # TODO: remove
    @workflow = UploadWorkflow::Bulk.generate(rec, **opt)
    @workflow.send("#{event}!", *data) or failure(from, @workflow.failed)
    # noinspection RubyYardReturnMatch
    @workflow.results
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a response to a POST.
  #
  # @param [Symbol, Integer, Exception] status
  # @param [String, Exception]          item
  # @param [String]                     redirect
  # @param [Boolean]                    xhr       Override `request.xhr?`.
  # @param [Symbol]                     meth      Calling method.
  #
  # @return [*]
  #
  # == Variations
  #
  # @overload post_response(status, item = nil, redirect: nil, xhr: nil)
  #   @param [Symbol, Integer]   status
  #   @param [String, Exception] item
  #
  # @overload post_response(except, redirect: nil, xhr: nil)
  #   @param [Exception] except
  #
  def post_response(status, item = nil, redirect: nil, xhr: nil, meth: nil)
    meth ||= calling_method
    __debug_args("UPLOAD #{meth} #{__method__}", binding)
    status, item = [nil, status] if status.is_a?(Exception)

    if item.is_a?(Exception)
      status ||= (item.code            if item.respond_to?(:code))
      status ||= (item.response.status if item.respond_to?(:response))
      message = Array.wrap(item)
    else
      message = Array.wrap(item).map { |v| ErrorEntry[v] }
    end
    status ||= :bad_request

    opt = { meth: meth, status: status }
    xhr = request_xhr? if xhr.nil?
    if xhr && !redirect
      head status, 'X-Flash-Message': flash_xhr(*message, **opt)
    else
      if %i[ok found].include?(status) || (200..399).include?(status)
        flash_success(*message, **opt)
      else
        flash_failure(*message, **opt)
      end
      if redirect
        redirect_to(redirect)
      else
        redirect_back(fallback_location: upload_index_path)
      end
    end
  end

end

__loading_end(__FILE__)
