# app/controllers/concerns/api_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Generic API methods.
#
# TODO: Transitional; may go away.
#
module ApiConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'ApiConcern')
  end

  include BookshareConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the Bookshare API service.
  #
  # @return [BookshareService]
  #
  def api
    bs_api
  end

  # Update the Bookshare API service.
  #
  # @param [Hash] opt
  #
  # @return [BookshareService]
  #
  def api_update(**opt)
    bs_api_update(**opt)
  end

  # Remove the Bookshare API service.
  #
  # @return [nil]
  #
  def api_clear
    bs_api_clear
  end

  # Indicate whether the Bookshare API service has been activated.
  #
  def api_active?
    bs_api_active?
  end

  # Indicate whether the latest Bookshare API request generated an exception.
  #
  def api_error?
    bs_api_error?
  end

  # Get the current Bookshare API exception message.
  #
  # @return [String]
  # @return [nil]
  #
  def api_error_message
    bs_api_error_message
  end

  # Get the current Bookshare API exception.
  #
  # @return [Exception]
  # @return [nil]
  #
  def api_exception
    bs_api_exception
  end

end

__loading_end(__FILE__)
