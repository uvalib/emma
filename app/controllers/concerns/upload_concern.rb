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
  end

  include IngestConcern
  include ParamsHelper
  include FlashHelper

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  MIME_REGISTRATION =
    FileNaming.format_classes.values.each(&:register_mime_types)

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

  # Exception raised when a submission is incomplete or invalid.
  #
  class SubmitError < StandardError

    # Initialize a new instance.
    #
    # @param [String, nil] msg
    #
    # This method overrides:
    # @see StandardError#initialize
    #
    def initialize(msg = nil)
      super(msg || 'unknown') # TODO: I18n
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # POST/PUT/PATCH parameters from the upload form that are not relevant to the
  # create/update of an Upload instance.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_UPLOAD_FORM_PARAMETERS = %i[limit field-control].sort.freeze

  # Extract POST parameters that are usable for creating/updating an Upload
  # instance.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `#url_parameters`
  #
  # @return [Hash{Symbol=>String}]
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
    result = url_parameters(p)
    result.except!(*IGNORED_UPLOAD_FORM_PARAMETERS)
    result.deep_symbolize_keys!
    upload = result.delete(:upload) || {}
    file   = upload[:file]
    result[:file_data] = file unless file.blank? || (file == '{}')
    reject_blanks(result)
  end

  # Process inserted or updated Upload records.
  #
  # @param [Array<Upload,Array<Upload>>] items  @see #collect_items
  #
  # @return [Array<(Array,Array)>]    Succeeded names and failed record IDs.
  #
  # @see #add_to_index
  #
  def finalize_upload(*items)
    items, failed = collect_items(*items)
    add_to_index(*items) unless failed.present?
    succeeded = items.map(&:filename)
    return succeeded, failed
  end

  # destroy_upload
  #
  # @param [Array<Upload,String,Array>] items   @see #collect_items
  # @param [Boolean]                    force   Force removal of index entries
  #                                               even if the related database
  #                                               entries do not exist.
  #
  # @return [Array<(Array,Array)>]    Succeeded paths and failed record IDs.
  #
  # @see #remove_from_index
  #
  def destroy_upload(*items, force: false)
    succeeded = []
    items, failed = collect_items(*items, force: force)
    remove_from_index(*items, force: force) unless failed.present?
    items = [] if failed.present?
    items.each do |item|
      if item.is_a?(Upload)
        name = item.filename
        if item.destroy # TODO: Delete the file too
          succeeded << name
        else
          failed << name
        end
      else
        succeeded << "item #{item}" # TODO: I18n
      end
    end
    return succeeded, failed
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Add the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload,String,Array>] items   @see #collect_items
  #
  # @return [Array<(Array,Array)>]    Succeeded names and failed names.
  #
  # TODO: schedule async index update job
  #
  def add_to_index(*items)
    items, failed = collect_items(*items)
    if items.present? && failed.blank?
      result = ingest_api.put_records(*items)
      fail(result.exception) if result.exception.present?
    end
    items.map!(&:id)
    return items, failed
  end

  # Remove the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload,String,Array>] items   @see #collect_items
  # @param [Boolean]                    force   Force removal of index entries
  #                                               even if the related database
  #                                               entries do not exist.
  #
  # @return [Array<(Array,Array)>]    Succeeded names and failed names.
  #
  # TODO: schedule async index deletion job?
  #
  def remove_from_index(*items, force: false)
    items, failed = collect_items(*items, force: force)
    if items.present? && failed.blank?
      result = ingest_api.delete_records(*items)
      fail(result.exception) if result.exception.present?
    end
    items = items.map { |item| item.respond_to?(:id) ? item.id : item }
    return items, failed
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a mixture of Upload objects and record identifiers into a list of
  # Upload objects.
  #
  # @param [Array<Upload,String,Array>] items   @see Upload#collect_ids
  # @param [Boolean]                    force   See Usage Notes
  #
  # @return [Array<(Array<Upload>,Array)>]      Upload records and failed ids.
  # @return [Array<(Array<Upload,String>,[])>]  If *force* is *true*.
  #
  # == Usage Notes
  # If *force* is true, the returned list of failed records will be empty but
  # the returned list of items may contain a mixture of Upload and String
  # elements.
  #
  def collect_items(*items, force: false)
    failed = []
    items =
      items.flatten.flat_map { |item|
        next if item.blank?
        next item if item.is_a?(Upload)
        # noinspection RubyYardParamTypeMatch
        Upload.collect_ids(item).map do |identifier|
          record = Upload.get_record(identifier)
          failed << identifier unless record || force
          record || identifier
        end
      }.compact
    return items, failed
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Placeholder error message.
  #
  # @type [String]
  #
  DEFAULT_ERROR_MESSAGE = I18n.t('emma.error.default', default: 'ERROR').freeze

  # Error types and messages.
  #
  # @type [Hash{Symbol=>Array<(String,Class)>}]
  #
  # noinspection RailsI18nInspection
  UPLOAD_ERROR =
    I18n.t('emma.error.upload').transform_values { |properties|
      text = properties[:message]
      err  = properties[:error]
      err  = "Net::#{err}" if err.is_a?(String) && !err.start_with?('Net::')
      err  = err&.constantize unless err.is_a?(Module)
      err  = err.exception_type if err.respond_to?(:exception_type)
      [text, err]
    }.symbolize_keys.deep_freeze

  # Raise an exception.
  #
  # @overload fail(msg, value = nil)
  #   @param [Symbol] problem         #UPLOAD_ERROR key.
  #   @param [*]      value
  #
  # @overload fail(msg)
  #   @param [String, Array<String>, Exception, ActiveModel::Errors] problem
  #
  # @raise [Net::ProtocolError]
  # @raise [StandardError]
  #
  def fail(problem, value = nil)
    err = nil
    case problem
      when Symbol              then msg, err = UPLOAD_ERROR[problem]
      when Api::Error          then msg = problem.messages
      when Exception           then msg = problem.message
      when ActiveModel::Errors then msg = problem.full_messages
      else                          msg = problem
    end
    err = SubmitError unless err.is_a?(Exception)
    msg = Array.wrap(msg)
    msg = msg.map { |t| t.to_s % value } if value
    msg = msg.join('; ').presence || DEFAULT_ERROR_MESSAGE
    raise err, msg
  end

  # Generate a response to a POST.
  #
  # @overload post_response(status, message = nil, redirect: nil, xhr: nil)
  #   @param [Symbol, Integer]   status
  #   @param [String, Exception] message
  #   @param [String]            redirect
  #   @param [Boolean]           xhr        Force XHR handling.
  #
  # @overload post_response(ex, redirect: nil, xhr: nil)
  #   @param [Exception] ex
  #   @param [String]    redirect
  #   @param [Boolean]   xhr                Force XHR handling.
  #
  def post_response(status, message = nil, redirect: nil, xhr: nil)
    status, message = [nil, status] if status.is_a?(Exception)
    status ||= :bad_request
    xhr    ||= request_xhr?
    except   = (message if message.is_a?(Exception))
    if except
      if except.respond_to?(:code)
        status = except.code || status
      elsif except.respond_to?(:response)
        status = except.response.status || status
      end
      Log.error do
        "#{__method__}: #{status}: #{except.class}: #{except.full_message}"
      end
      message = except.message
    end
    message = Array.wrap(message).map { |m| m.inspect.truncate(1024) }.presence
    unless except
      Log.info do
        [__method__, status, message&.join(', ')].compact.join(': ')
      end
    end
    if redirect || !xhr
      if %i[ok found].include?(status) || (200..399).include?(status)
        flash_success(*message)
      else
        flash_failure(*message)
      end
      if redirect
        redirect_to(redirect)
      else
        redirect_back(fallback_location: upload_index_path)
      end
    else
      message ||= DEFAULT_ERROR_MESSAGE
      message = safe_json_parse(message).to_json.truncate(1024)
      head status, 'X-Flash-Message': message
    end
  end

end

__loading_end(__FILE__)
