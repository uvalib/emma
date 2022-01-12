# app/helpers/bs_api_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the "Bookshare API Explorer" ("/bs_api" pages).
#
module BsApiHelper

  include Emma::Common

  include ApiHelper

  extend self

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include BookshareConcern
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a URL to an external (Bookshare-related) site, refactored so that
  # it passes through the application's "Bookshare API Explorer" endpoint.
  #
  # @param [String] path
  # @param [Hash]   prm               Passed to #make_path.
  #
  # @return [String]
  #
  def bs_api_explorer_url(path, **prm)
    api_version = "/#{BOOKSHARE_API_VERSION}/"
    make_path(path, **prm).tap do |result|
      result.delete_prefix!(BOOKSHARE_BASE_URL)
      unless result.start_with?('http', api_version)
        result.prepend(api_version).squeeze!('/')
      end
    end
  end

  # Invoke a Bookshare API method for display in the "Bookshare API Explorer".
  #
  # @param [Symbol] meth              One of ApiService#HTTP_METHODS.
  # @param [String] path
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def bs_api_explorer(meth, path, **opt)
    meth = meth&.downcase&.to_sym || :get
    data = bs_api.api(meth, path, **opt.merge(no_raise: true))&.body&.presence
    {
      method:    meth.to_s.upcase,
      path:      path,
      opt:       opt.presence || '',
      url:       bs_api_explorer_url(path, **opt),
      result:    data&.force_encoding('UTF-8'),
      exception: api_exception,
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
