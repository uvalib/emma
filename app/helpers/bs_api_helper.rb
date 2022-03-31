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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  BOOKSHARE_USER = '%s@bookshare.org'

  # Transform name(s) into Bookshare username(s).
  #
  # @param [String, Symbol, Array<String,Symbol>] name
  #
  # @return [String]
  # @return [Array<String>]
  #
  #--
  # == Variations
  #++
  #
  # @overload bookshare_user(name)
  #   @param [String, Symbol] name
  #   @return [String]
  #
  # @overload bookshare_user(names)
  #   @param [Array<String,Symbol>] names
  #   @return [Array<String>]
  #
  def bookshare_user(name)
    return name.map { |v| send(__method__, v) } if name.is_a?(Array)
    name = name.to_s.downcase
    # noinspection RubyMismatchedReturnType
    (name.present? && !name.include?('@')) ? (BOOKSHARE_USER % name) : name
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
