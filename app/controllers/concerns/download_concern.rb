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
  # @param [Symbol] method  API request method.
  # @param [Hash]   opt     Passed to the request method.
  #
  # @return [void]
  #
  def render_download(method, **opt)
    # @type [Search::Message::RetrievalResult, Bs::Message::StatusModel] result
    result = api.send(method, **opt.merge!(no_raise: true, no_redirect: true))
    @exception = result.exception
    @error     = result.error_message
    @state     = result.key.to_s.upcase
    @link      = (result.messages.first.presence if @state == 'COMPLETED')
    respond_to do |format|
      format.html { @link ? redirect_to(@link) : render(layout: layout) }
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
