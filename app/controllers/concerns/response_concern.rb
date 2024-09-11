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
  # @param [any, nil]        error    Exception, String
  # @param [Integer, Symbol] status
  # @param [Boolean]         xhr
  # @param [String, Symbol]  action
  # @param [Symbol]          meth
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
    opt      = { meth: meth, status: status }
    xhr      = request_xhr? if xhr.nil?
    xml      = request.format.xml?
    json     = request.format.json?
    html     = !xhr && !xml && !json && request.format.html?
    message  = report.render(html: html)
    case
      when xml  then render_xml( { error: message.join('; ') })
      when json then render_json({ error: message.join('; ') })
      when html then flash_now_failure(*message, **opt)
      else           headers['X-Flash-Message'] = flash_xhr(*message, **opt)
    end
    self.status = status
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default redirect path for #redirect_back_or_to.
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
      self.class.name.underscore.split('_')[...-1].join('_').upcase
  end

  # Display the failure on the screen -- immediately if modal, or after a
  # redirect otherwise.
  #
  # If *error* is a CanCan::AccessDenied then *redirect* defaults to
  # #welcome_path since this is a destination that is guaranteed to be safe for
  # an anonymous user.
  #
  # @param [Exception, Model, String] error
  # @param [String, nil]              redirect  Def: *fallback*
  # @param [String, nil]              fallback  Def: #default_fallback_location
  # @param [Hash]                     opt       To #flash_failure/#flash_status
  #
  # @return [void]
  #
  def error_response(error, redirect = nil, fallback: nil, **opt)
    opt[:meth] ||= calling_method
    return failure_status(error, **opt)   if modal? || !request.format.html?
    re_raise_if_internal_exception(error) if error.is_a?(Exception)
    flash_failure(error, **opt)
    if error.is_a?(CanCan::AccessDenied) || http_forbidden?(opt[:status])
      redirect_to(redirect || welcome_path)
    else
      redirect_back_or_to(redirect || fallback || default_fallback_location)
    end
  end

  # Generate a response to a POST.
  #
  # If *status* is :forbidden or *item* is a CanCan::AccessDenied then
  # *redirect* defaults to #welcome_path since this is a destination that is
  # guaranteed to be safe for an anonymous user.
  #
  # @param [Symbol, Integer, Exception, nil] status
  # @param [any, nil]                        item      Array
  # @param [String, FalseClass]              redirect
  # @param [Boolean]                         xhr       Override `request.xhr?`
  # @param [Symbol]                          meth      Calling method.
  # @param [String]                          tag       Default: #response_tag.
  # @param [String]                          fallback  For #redirect_back_or_to
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
  #   @param [any, nil]         items   Array
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

    error      = item.is_a?(Exception) and re_raise_if_internal_exception(item)
    report     = item.presence && ExecReport[item]
    status   ||= report&.http_status
    status   ||= (:forbidden if item.is_a?(CanCan::AccessDenied))
    status   ||= error ? :bad_request : :ok
    forbidden  = http_forbidden?(status)
    success    = !forbidden && http_success?(status)
    xhr        = request_xhr?               if xhr.nil?
    redirect   = params[:redirect]          if redirect.nil?
    redirect   = welcome_path               if redirect.nil? && forbidden
    redirect   = http_redirect?(status)     if redirect.nil? && !xhr
    redirect   = true?(redirect)            if boolean?(redirect)
    back       = redirect.is_a?(TrueClass)
    fallback ||= default_fallback_location  if back

    # @see https://github.com/hotwired/turbo/issues/492
    if redirect && !xhr
      if request.get? || request.post?
        status = :found     unless http_redirect?(status)
      else
        status = :see_other unless http_permanent_redirect?(status)
      end
    end

    if (msg = report).blank?
      msg = (item.is_a?(Array) ? item.flatten : [item]).compact.presence
      msg&.map! { make_label(_1) || _1.to_s }
    end
    if msg.present?
      f_opt = { meth: meth, status: status }
      case
        when xhr     then msg = { 'X-Flash-Message': flash_xhr(*msg, **f_opt) }
        when success then flash_success(*msg, **f_opt)
        else              flash_failure(*msg, **f_opt)
      end
    end

    # noinspection RubyMismatchedArgumentType
    case
      when xhr      then head status, (msg || {})
      when back     then redirect_back_or_to(fallback, status: status)
      when redirect then redirect_to(redirect, status: status)
      when error    then raise(item)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Render an item for display in a message.
  #
  # @param [any, nil] item            Model, Hash, String
  #
  # @return [String, nil]
  #
  def make_label(item)
    item.try(:menu_label) || item.try(:render)
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
