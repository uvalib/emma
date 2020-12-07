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

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return a member associated with the given user.
  #
  # @param [User, String] for_user    Default: `#current_user`.
  # @param [String]       _name       Member name (future).
  #
  # @return [String]
  #
  def get_member(for_user = nil, _name = nil)
    for_user ||= current_user
    for_user = User.find_by(email: for_user) if for_user.is_a?(String)
    case for_user&.uid
      when BookshareService::BOOKSHARE_TEST_ACCOUNT
        BookshareService::BOOKSHARE_TEST_MEMBER
      else
        # TODO: Member lookup
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Extract the best-match URL parameter which represents an item identifier.
  #
  # @return [String]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :bookshareId found.
  #
  def set_bookshare_id
    # noinspection RubyYardReturnMatch
    @bookshare_id = params[:bookshareId] || params[:id]
  end

  # Extract the URL parameter which specifies a journal/periodical series.
  #
  # @return [String]                  Value of `params[:series]`.
  # @return [nil]                     No :series, :seriesId found.
  #
  def set_series_id
    # noinspection RubyYardReturnMatch
    @series_id = params[:seriesId] || params[:series] || params[:id]
  end

  # Extract the URL parameter which specifies a journal/periodical edition.
  #
  # @return [String]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :edition, :editionId found.
  #
  def set_edition_id
    # noinspection RubyYardReturnMatch
    @edition_id = params[:editionId] || params[:edition] || params[:id]
  end

  # Extract the best-match URL parameter which represents an item format.
  #
  # @return [String]                  Value of `params[:fmt]`.
  # @return [nil]                     No :fmt found.
  #
  def set_format
    # noinspection RubyYardReturnMatch
    @format = params[:fmt] || FormatType.default
  end

  # Extract the URL parameter which specifies a reading list.
  #
  # @return [String]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :readingListId found.
  #
  def set_reading_list_id
    # noinspection RubyYardReturnMatch
    @id = params[:readingListId] || params[:id]
  end

  # Extract the URL parameter which indicates a Bookshare member.
  #
  # @return [String]                  Value of `params[:member]`.
  # @return [nil]                     No :member, :forUser found.
  #
  def set_member
    @member = params[:forUser] || params[:member] || get_member
  end

  # Extract the URL parameter which indicates a remote URL path.
  #
  # @return [String]                  Value of `params[:url]`.
  # @return [nil]                     No :url found.
  #
  def set_url
    # noinspection RubyYardReturnMatch
    @url = params[:url]
  end

end

__loading_end(__FILE__)
