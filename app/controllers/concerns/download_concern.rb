# app/controllers/concerns/download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# DownloadConcern
#
module DownloadConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'DownloadConcern')

    include BookshareConcern

  end

  include SerializationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # render_download
  #
  # @overload render_download(method, **opt)
  #   @param [Symbol] method  API request method.
  #   @param [Hash]   opt     Passed to the request method.
  #
  # @overload render_download(result)
  #   @param [Bs::Message::StatusModel] result
  #
  def render_download(method, **opt)
    result =
      if method.is_a?(Api::Message)
        method
      else
        api.send(method, **opt.merge(no_raise: true, no_redirect: true))
      end
    @error     = result.error_message
    @state     = result.key.to_s.upcase
    @link      = (result.messages.first.presence if @state == 'COMPLETED')
    @exception = result.exception
    respond_to do |format|
      format.html { redirect_to @link if @link }
      format.json { render_json download_values }
      format.xml  { render_xml  download_values }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Response values for de-serializing download information to JSON or XML.
  #
  # @param [String] url
  # @param [String] state
  # @param [String] error
  #
  # @return [Hash{Symbol=>String}]
  #
  def download_values(url = @link, state = @state, error = @error)
    { url: url, state: state }.tap do |result|
      result[:error] = error if error.present?
    end
  end

end

__loading_end(__FILE__)
