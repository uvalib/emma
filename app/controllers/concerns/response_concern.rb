# app/controllers/concerns/response_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for failure responses.
#
module ResponseConcern

  extend ActiveSupport::Concern

  include FlashHelper
  include HttpHelper

  include ParamsConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a flash message if there is an error.
  #
  # @param [Exception, String, *] error
  # @param [Integer, Symbol]      status
  # @param [Boolean]              xhr
  # @param [String, Symbol]       action
  # @param [Symbol]               meth
  #
  # @return [Integer, Symbol]         HTTP status.
  # @return [nil]                     If *error* is nil.
  #
  def failure_status(error, status: nil, xhr: nil, action: nil, meth: nil, **)
    return unless error
    re_raise_if_internal_exception(error) if error.is_a?(Exception)
    meth   ||= calling_method
    report   = ExecReport[error]
    action ||= params[:action]
    status ||= report.http_status
    status ||= (action&.to_sym == :index) ? :bad_request : :not_found
    xhr      = request_xhr? if xhr.nil?
    html     = !xhr && request.format.html?
    message  = report.render(html: html)
    opt      = { meth: meth, status: status }
    if html
      flash_now_failure(*message, **opt)
    else
      headers['X-Flash-Message'] = flash_xhr(*message, **opt)
    end
    self.status = status
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default redirect path for #redirect_back.
  #
  # @return [String]
  #
  def default_fallback_location
    root_path
  end

  # Prefix for response diagnostic logging.
  #
  # @return [String]
  #
  def response_tag
    @response_tag ||=
      self.class.name.underscore.split('_')[0...-1].join('_').upcase
  end

  # Display the failure on the screen -- immediately if modal, or after a
  # redirect otherwise.
  #
  # @param [Exception] error
  # @param [String]    fallback   Redirect fallback #default_fallback_location
  # @param [Symbol]    meth       Calling method.
  #
  # @return [void]
  #
  def error_response(error, fallback = nil, meth: nil)
    meth ||= calling_method
    if modal?
      failure_status(error, meth: meth)
    else
      re_raise_if_internal_exception(error)
      flash_failure(error, meth: meth)
      redirect_back(fallback_location: fallback || default_fallback_location)
    end
  end

  # Generate a response to a POST.
  #
  # @param [Symbol, Integer, Exception, nil] status
  # @param [Array, *]                        item
  # @param [String, FalseClass]              redirect
  # @param [Boolean]                         xhr        Override `request.xhr?`
  # @param [Symbol]                          meth       Calling method.
  # @param [String]                          tag        Default: #response_tag.
  # @param [String]                          fallback   For #redirect_back.
  #
  # @return [void]
  #
  #--
  # === Variations
  #++
  #
  # @overload post_response(error, ...)
  #   @param [Exception]        error
  #
  # @overload post_response(status, error, ...)
  #   @param [Symbol, Integer]  status
  #   @param [Exception]        error
  #
  # @overload post_response(status, items, ...)
  #   @param [Symbol, Integer]  status
  #   @param [Array, *]         items
  #
  def post_response(
    status,
    item =    nil,
    redirect: nil,
    xhr:      nil,
    meth:     nil,
    tag:      nil,
    fallback: nil,
    **
  )
    tag  ||= response_tag
    meth ||= calling_method
    __debug_items("#{tag} #{meth} #{__method__}", binding)

    unless status.is_a?(Symbol) || status.is_a?(Integer)
      status, item = [nil, status]
    end
    re_raise_if_internal_exception(item) if (error = item.is_a?(Exception))

    xhr      = request_xhr? if xhr.nil?
    html     = !xhr || redirect.present?
    report   = item.presence && ExecReport[item]
    status ||= report&.http_status
    status ||= error ? :bad_request : :ok
    success  = http_success?(status)
    redirect = html && http_redirect?(status) if redirect.nil?

    # @see https://github.com/hotwired/turbo/issues/492
    if html && redirect
      if request.get? || request.post?
        status = :found     unless http_redirect?(status)
      else
        status = :see_other unless http_permanent_redirect?(status)
      end
    end

    message   = report&.render(html: html)&.presence
    message ||= Array.wrap(item).flatten.map { |v| make_label(v) }.presence
    if message
      flash_opt = { meth: meth, status: status }
      if xhr
        message = { 'X-Flash-Message': flash_xhr(*message, **flash_opt) }
      elsif success
        flash_success(*message, **flash_opt)
      else
        flash_failure(*message, **flash_opt)
      end
    end

    if xhr
      head status, (message || {})
    elsif redirect.is_a?(String)
      redirect_to(redirect, status: status)
    elsif redirect
      fallback ||= default_fallback_location
      redirect_back(fallback_location: fallback, status: status)
    elsif error
      # noinspection RubyMismatchedArgumentType
      raise(item)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Render an item for display in a message.
  #
  # @param [Model, Hash, String, *] item
  #
  # @return [String]
  #
  def make_label(item, **opt)
    if item.is_a?(Model)
      Record::Rendering.make_label(item, **opt)
    else
      item.try(:render) || item.to_s
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
