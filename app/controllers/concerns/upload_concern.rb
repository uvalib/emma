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

  # Insert or update Upload records.
  #
  # @param [Array<Upload,String,Array>] items
  #
  # @return [Array<(Array,Array)>]    Succeeded paths and failed record IDs.
  #
  def finalize_upload(*items)
    items, failed = collect_items(*items)
    add_to_index(*items) if failed.blank? # TODO: schedule index update
    succeeded = items.map(&:filename)
    return succeeded, failed
  end

  # destroy_upload
  #
  # @param [Array<Upload,String,Array>] items
  #
  # @return [Array<(Array,Array)>]    Succeeded paths and failed record IDs.
  #
  def destroy_upload(*items)
    items, failed = collect_items(*items)
    succeeded = []
    unless failed.present?
      remove_from_index(*items) # TODO: schedule index update
      items.map do |item|
        name = item.filename
        # TODO: Remove file from storage
        # TODO: Remove record from 'uploads' table
        item.destroy! # TODO: Can this be set up to delete the file?
        succeeded << name
      end
    end
    return succeeded, failed
  end

  # Translate into an array of Upload instances.
  #
  # @param [String, Upload, Array<String,Upload>] item
  #
  # @return [Array<Upload>]
  #
  def upload_submission(item)
    item = item.gsub(/\s/, '') if item.is_a?(String)
    item = item.split(',')     if item.is_a?(String) && item.include?(',')
    # noinspection RubyYardReturnMatch
    case item
      when Upload then [item]
      when String then [Upload.find(email: item)]
      when Array  then item.flat_map { |i| upload_submission(i) }.compact
      else             []
    end
  end

  # ===========================================================================
  # :section: TODO: temporary
  # ===========================================================================

  public

  # add_to_index
  #
  # @param [Array<Upload,String,Array>] items
  #
  # @return [Array<(Array,Array)>]    Succeeded names and failed names.
  #
  def add_to_index(*items)
    items, failed = collect_items(*items)
    if items.present? && failed.blank?
      result = ingest_api.put_records(*items)
      fail(result.exception) if result.exception.present?
    end
    return items.map(&:id), failed
  end

  # remove_from_index
  #
  # @param [Array<Upload,String,Array>] items
  #
  # @return [Array<(Array,Array)>]    Succeeded names and failed names.
  #
  def remove_from_index(*items)
    items, failed = collect_items(*items)
    if items.present? && failed.blank?
      result = ingest_api.delete_records(*items)
      fail(result.exception) if result.exception.present?
    end
    return items.map(&:id), failed
  end

  # Transform a mixture of Upload objects and record identifiers.
  #
  # @param [Array<Upload,String,Array>] items
  #
  # @return [Array<(Array,Array)>]    Upload records and a list of failed ids.
  #
  def collect_items(*items)
    failed = []
    items =
      items.flatten.flat_map { |item|
        if item.is_a?(Upload)
          item
        elsif item.present?
          item = item.include?(',') ? item.split(/\s*,\s*/) : Array.wrap(item)
          item.map { |id| Upload.find(id).tap { |u| failed << id unless u } }
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
    xhr ||= request_xhr?
    exception = (message if message.is_a?(Exception))
    if exception
      message = exception.message
      if exception.respond_to?(:code)
        status = exception.code
      elsif exception.respond_to?(:response)
        status = exception.response.status
      end
    end
    status ||= :bad_request
    Log.info {
      [__method__, status, exception&.class, message].compact.join(': ')
    }
    if redirect || !xhr
      if message.is_a?(Array)
        message = message.map { |m| m.truncate(1024) }.join("\n")
      end
      message = message&.truncate(1024)
      if %i[ok found].include?(status) || (200..399).include?(status)
        flash_success(message)
      else
        flash_failure(message)
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
