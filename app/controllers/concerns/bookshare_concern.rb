# app/controllers/concerns/bookshare_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Included by a controller to use the Bookshare API.
#
module BookshareConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'BookshareConcern')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the Bookshare API service.
  #
  # @return [BookshareService]
  #
  def bs_api
    @bs_api ||= bs_api_update
  end

  # Update the Bookshare API service.
  #
  # @param [Hash] opt
  #
  # @return [BookshareService]
  #
  def bs_api_update(**opt)
    opt[:user] = current_user if !opt.key?(:user) && current_user.present?
    opt[:no_raise] = true     if !opt.key?(:no_raise) && Rails.env.test?
    # noinspection RubyYardReturnMatch
    @bs_api = BookshareService.update(**opt)
  end

  # Remove the Bookshare API service.
  #
  # @return [nil]
  #
  def bs_api_clear
    @bs_api = BookshareService.clear
  end

  # Indicate whether the Bookshare API service has been activated.
  #
  def bs_api_active?
    defined?(:@bs_api) && @bs_api.present?
  end

  # Indicate whether the latest Bookshare API request generated an exception.
  #
  def bs_api_error?
    bs_api_active? && @bs_api&.error?
  end

  # Get the current Bookshare API exception message.
  #
  # @return [String]                  Current service error message.
  # @return [nil]                     No service error or service not active.
  #
  def bs_api_error_message
    @bs_api&.error_message if bs_api_active?
  end

  # Get the current Bookshare API exception.
  #
  # @return [Exception]               Current service exception.
  # @return [nil]                     No exception or service not active.
  #
  def bs_api_exception
    @bs_api&.exception if bs_api_active?
  end

end

__loading_end(__FILE__)
