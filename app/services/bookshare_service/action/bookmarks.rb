# app/services/bookshare_service/action/bookmarks.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Action::Bookmarks
#
# == Usage Notes
#
# === From API section 2.11 (Bookmarks):
# A bookmark represents a location in a title that a user wants to save.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Action::Bookmarks

  include BookshareService::Common
  include BookshareService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myBookmarks
  #
  # == 2.11.1. Get bookmarks for a title
  # Get the bookmarks made by the current user on the given title and format.
  #
  # @param [String] bookshareId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String]  format      One of `BsFormatType#values`
  #
  # @return [Bs::Message::BookmarkList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-bookmarks
  #
  def get_bookmark(bookshareId:, **opt)
    opt.merge!(bookshareId: bookshareId)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myBookmarks', **opt)
    api_return(Bs::Message::BookmarkList)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId:  String,
        },
        optional: {
          format:       BsFormatType,
        },
        reference_id: '_get-bookmarks'
      }
    end

  # == POST /v2/myBookmarks
  #
  # == 2.11.2. Submit a bookmark
  # Submit a new or updated bookmark to save a location within a title.
  #
  # @param [String]  bookshareId
  # @param [String]  location
  # @param [Hash]    opt                    Passed to #api.
  #
  # @option opt [String]  format            One of `BsFormatType#values`
  # @option opt [String]  text
  # @option opt [Integer] position
  # @option opt [Float]   progression
  # @option opt [Float]   totalProgression
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_post-bookmark
  #
  def submit_bookmark(bookshareId:, location:, **opt)
    opt.merge!(bookshareId: bookshareId, location: location)
    opt = get_parameters(__method__, **opt)
    api(:post, 'myBookmarks', **opt)
    api_return(Bs::Message::StatusModel)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId:      String,
          location:         String,
        },
        optional: {
          format:           BsFormatType,
          text:             String,
          position:         Integer,
          progression:      Float,
          totalProgression: Float,
        },
        reference_id: '_post-bookmark'
      }
    end

  # == DELETE /v2/myBookmarks
  #
  # == 2.11.3. Delete a bookmark for a title
  # Delete a bookmark made by the current user on the given title and format at
  # the given location.
  #
  # @param [String]  bookshareId
  # @param [String]  location
  # @param [Hash]    opt                    Passed to #api.
  #
  # @option opt [String]  format            One of `BsFormatType#values`
  #
  # @return [Bs::Message::BookmarkList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_delete-bookmark
  #
  def delete_bookmark(bookshareId:, location:, **opt)
    opt.merge!(bookshareId: bookshareId, location: location)
    opt = get_parameters(__method__, **opt)
    api(:delete, 'myBookmarks', **opt)
    api_return(Bs::Message::BookmarkList)
  end
    .tap do |method|
    add_api method => {
      required: {
        bookshareId:  String,
        location:     String,
      },
      optional: {
        format:       BsFormatType,
      },
      reference_id:   '_delete-bookmark'
    }
  end

end

__loading_end(__FILE__)
