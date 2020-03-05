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

  # destroy_upload
  #
  # @param [Upload] item
  #
  # @return [String]
  # @return [nil]
  #
  def destroy_upload(item)
    return if item.blank?
    name = item.filename
    # TODO: Remove file from storage
    # TODO: Remove record from 'uploads' table
    item.destroy! # TODO: Can this be set up to delete the file?
    # TODO: Schedule removal from unified search
    name
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Error messages. # TODO: I18n
  #
  # @type [Hash{Symbol=>String}]
  #
  ERROR = {
    file_data: [Net::HTTPBadRequest, 'No file data provided'],
    file_id:   [Net::HTTPBadRequest, 'No entry identifier provided'],
    find:      [Net::HTTPNotFound,   'Entry %s not found'],
    create:    [Net::HTTPConflict,   'Failed to create entry'],
    invalid:   [Net::HTTPConflict,   'Issues to resolve: %s'],
  }.deep_freeze

  # Raise an exception.
  #
  # @overload fail(msg)
  #   @param [String, Array<String>, ActiveModel::Errors] msg
  #
  # @overload fail(msg, value = nil)
  #   @param [Symbol] msg             #ERROR key.
  #   @param [*]      value
  #
  # @raise [Net::ProtocolError]
  # @raise [StandardError]
  #
  def fail(msg, value = nil)
    err = nil
    if msg.is_a?(Symbol)
      err, msg = ERROR[msg]
      # noinspection RubyRedundantSafeNavigation
      msg = msg % Array.wrap(value).join('; ') if msg&.include?('%')
    end
    # noinspection RubyNilAnalysis
    err = err.respond_to?(:exception_type) ? err.exception_type : SubmitError
    msg = msg.full_messages if msg.is_a?(ActiveModel::Errors)
    msg = Array.wrap(msg).join('; ').presence || 'unknown error' # TODO: I18n
    raise err, msg
  end

  # Generate a response to a POST.
  #
  # @overload post_response(status, message = nil, redirect: nil)
  #   @param [Symbol, Integer]   status
  #   @param [String, Exception] message
  #   @param [String]            redirect
  #   @param [Boolean]           xhr        Force XHR handling.
  #
  # @overload post_response(ex, redirect: nil)
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
      message ||= I18n.t('emma.error.default')
      message = safe_json_parse(message).to_json.truncate(1024)
      head status, 'X-Flash-Message': message
    end
  end

end

__loading_end(__FILE__)
