# app/controllers/concerns/bookshare_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for access to the Bookshare API service.
#
module BookshareConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'BookshareConcern')
  end

  include ApiConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the Bookshare API service.
  #
  # @return [BookshareService]
  #
  def bs_api
    # noinspection RubyYardReturnMatch
    api_service(BookshareService)
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
  # @return [nil]
  #
  def get_member(for_user = nil, _name = nil)
    for_user = User.find_record(for_user || current_user)
    case for_user&.bookshare_uid
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
    @format = params[:fmt] || BsFormatType.default
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
