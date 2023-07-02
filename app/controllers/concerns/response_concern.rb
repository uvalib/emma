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
  include ParamsHelper

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

  # Generate a response to a POST.
  #
  # @param [Symbol, Integer, Exception, nil] status
  # @param [Array, *]                        item
  # @param [String, FalseClass]              redirect
  # @param [Boolean]                         xhr        Override `request.xhr?`
  # @param [Symbol]                          meth       Calling method.
  # @param [String]                          tag        For diagnostics.
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
    meth ||= calling_method
    tag  ||= meth
    __debug_items("#{tag} #{__method__}", binding)

    unless status.is_a?(Symbol) || status.is_a?(Integer)
      status, item = [nil, status]
    end
    re_raise_if_internal_exception(item) if item.is_a?(Exception)

    xhr        = request_xhr? if xhr.nil?
    html       = !xhr || redirect.present?
    report     = item.presence && ExecReport[item]
    status   ||= report&.http_status
    status   ||= item.is_a?(Exception) ? :bad_request : :ok
    success    = http_success?(status)
    redirect   = true if redirect.nil? && html && http_redirect?(status)
    fallback ||= root_path
    message    = report&.render(html: html)&.presence
    message  ||= Array.wrap(item).flatten.map { |v| make_label(v) }.presence

    # @see https://github.com/hotwired/turbo/issues/492
    if html && redirect
      if request.get? || request.post?
        status = :found     unless http_redirect?(status)
      else
        status = :see_other unless http_permanent_redirect?(status)
      end
    end
    flash_opt = { status: status, meth: meth }

    if html && message
      if success
        flash_success(*message, **flash_opt)
      else
        flash_failure(*message, **flash_opt)
      end
    end

    if xhr
      if message
        head status, 'X-Flash-Message': flash_xhr(*message, **flash_opt)
      else
        head status
      end
    elsif redirect
      if redirect.is_a?(String)
        redirect_to(redirect, status: status)
      else
        redirect_back(fallback_location: fallback, status: status)
      end
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
