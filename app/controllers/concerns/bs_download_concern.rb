# app/controllers/concerns/bs_download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for downloads from Bookshare.
#
module BsDownloadConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'BsDownloadConcern')
  end

  include BookshareConcern
  include SerializationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Redirect to a copy of an artifact generated by Bookshare.
  #
  # @param [Symbol] meth              API request method.
  # @param [Hash]   opt               Passed to the request method.
  #
  # @return [void]
  #
  def bs_download_response(meth, **opt)
    # @type [Search::Message::RetrievalResult, Bs::Message::StatusModel] result
    result = bs_api.send(meth, **opt.merge!(no_raise: true, no_redirect: true))
    @exception = result.exception
    @error     = result.error_message
    @state     = result.key.to_s.upcase
    @link      = (result.messages.first.presence if @state == 'COMPLETED')
    respond_to do |format|
      format.html { @link ? redirect_to(@link) : render }
      format.json { render_json bs_download_values }
      format.xml  { render_xml  bs_download_values }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Response values for de-serializing Bookshare download information to JSON
  # or XML.
  #
  # @param [String] url
  # @param [String] state
  # @param [String] error
  #
  # @return [Hash{Symbol=>String}]
  #
  def bs_download_values(url = @link, state = @state, error = @error)
    { url: url, state: state }.tap do |result|
      result[:error] = error if error.present?
    end
  end

end

__loading_end(__FILE__)
