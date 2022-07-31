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
  #
  def failure_response(error, status: nil, xhr: nil, action: nil, meth: nil)
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

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
