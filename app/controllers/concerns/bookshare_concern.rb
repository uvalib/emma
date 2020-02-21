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

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Access the Bookshare API service.
    #
    # @return [BookshareService]
    #
    def api
      @bs_api ||= api_update
    end

    # Update the Bookshare API service.
    #
    # @param [Hash] opt
    #
    # @return [BookshareService]
    #
    def api_update(**opt)
      default_opt = {}
      default_opt[:user]     = current_user if current_user.present?
      default_opt[:no_raise] = true         if Rails.env.test?
      # noinspection RubyYardReturnMatch
      @bs_api = BookshareService.update(**opt.reverse_merge(default_opt))
    end

    # Remove the Bookshare API service.
    #
    # @return [nil]
    #
    def api_clear
      @bs_api = BookshareService.clear
    end

    # Indicate whether the latest API request generated an exception.
    #
    def api_error?
      defined?(@bs_api) && @bs_api.present? && @bs_api.error?
    end

    # Get the current API exception message if the service has been started.
    #
    # @return [String]
    # @return [nil]
    #
    def api_error_message
      @bs_api.error_message if defined?(:@bs_api) && @bs_api.present?
    end

    # Get the current API exception if the service has been started.
    #
    # @return [Exception]
    # @return [nil]
    #
    def api_exception
      @bs_api.exception if defined?(:@bs_api) && @bs_api.present?
    end

  end

end

__loading_end(__FILE__)
