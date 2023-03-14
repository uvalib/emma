# app/services/bookshare_service/action/highlights.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Action::Highlights
#
# == Usage Notes
#
# === From API section 2.12 (Highlights):
# A highlight represents a selection of text at a location in a title that a
# user wants to save. Users are able to create, update, and remove highlights
# on titles they can access. Highlights are specific for a format, so the set
# of highlights a user creates when reading an EPUB3 version of a title will be
# different than any highlights they create when reading a DAISY version of the
# title.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Action::Highlights

  include BookshareService::Common
  include BookshareService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myHighlights
  #
  # == 2.31.1. Get highlights for a title
  # Get the highlights a user has made in a title of the given format.
  #
  # @param [String]       bookshareId
  # @param [Hash]         opt               Passed to #api.
  #
  # @option opt [String]  format            One of `BsFormatType#values`
  #
  # @return [Bs::Message::HighlightList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-highlight
  #
  def get_highlight(bookshareId:, **opt)
    opt.merge!(bookshareId: bookshareId)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myHighlights', **opt)
    api_return(Bs::Message::HighlightList)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId:  String,
        },
        optional: {
          format:       BsFormatType,
          start:        String,
          limit:        Integer,
        },
        reference_id:   '_get-highlight'
      }
    end

  # == PUT /v2/myHighlights
  #
  # == 2.13.2. Update a highlight
  # Update the annotation note or color of a highlight within a title of a
  # specific format.
  #
  # @param [String]  bookshareId
  # @param [String]  startLocation
  # @param [String]  endLocation
  # @param [Hash]    opt                    Passed to #api.
  #
  # @option opt [String]  format            One of `BsFormatType#values`
  # @option opt [String]  annotationNote
  # @option opt [String]  color
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-highlight
  #
  def update_highlight(bookshareId:, startLocation:, endLocation:, **opt)
    opt.merge!(bookshareId: bookshareId)
    opt.merge!(startLocation: startLocation, endLocation: endLocation)
    opt = get_parameters(__method__, **opt)
    api(:put, 'myHighlights', **opt)
    api_return(Bs::Message::StatusModel)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId:    String,
          startLocation:  String,
          endLocation:    String,
        },
        optional: {
          format:         BsFormatType,
          annotationNote: String,
          color:          String,
        },
        reference_id:     '_put-highlight'
      }
    end

  # == POST /v2/myHighlights
  #
  # == 2.11.3. Create a highlight
  # Create a new highlight within a title of a specific format.
  #
  # @param [String]  bookshareId
  # @param [String]  startLocation
  # @param [String]  endLocation
  # @param [Hash]    opt                    Passed to #api.
  #
  # @option opt [String]  format            One of `BsFormatType#values`
  # @option opt [String]  highlightText
  # @option opt [String]  annotationNote
  # @option opt [String]  color
  # @option opt [Integer] startPosition
  # @option opt [Float]   startProgression
  # @option opt [Float]   startTotalProgression
  # @option opt [Integer] endPosition
  # @option opt [Float]   endProgression
  # @option opt [Float]   endTotalProgression
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_post-highlight
  #
  def create_highlight(bookshareId:, startLocation:, endLocation:, **opt)
    opt.merge!(bookshareId: bookshareId)
    opt.merge!(startLocation: startLocation, endLocation: endLocation)
    opt = get_parameters(__method__, **opt)
    api(:post, 'myHighlights', **opt)
    api_return(Bs::Message::StatusModel)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId:            String,
          startLocation:          String,
          endLocation:            String,
        },
        optional: {
          format:                 BsFormatType,
          annotationNote:         String,
          color:                  String,
          startPosition:          Integer,
          startProgression:       Float,
          startTotalProgression:  Float,
          endPosition:            Integer,
          endProgression:         Float,
          endTotalProgression:    Float,
        },
        reference_id:             '_post-highlight'
      }
    end

  # == DELETE /v2/myHighlights
  #
  # == 2.13.4. Delete a highlight
  # Deletes a highlight made by the user for a title in a given format.
  #
  # @param [String]  bookshareId
  # @param [String]  startLocation
  # @param [String]  endLocation
  # @param [Hash]    opt                    Passed to #api.
  #
  # @option opt [String]  format            One of `BsFormatType#values`
  #
  # @return [Bs::Message::HighlightList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_delete-highlight
  #
  def delete_highlight(bookshareId:, startLocation:, endLocation:, **opt)
    opt.merge!(bookshareId: bookshareId)
    opt.merge!(startLocation: startLocation, endLocation: endLocation)
    opt = get_parameters(__method__, **opt)
    api(:delete, 'myHighlights', **opt)
    api_return(Bs::Message::HighlightList)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId:    String,
          startLocation:  String,
          endLocation:    String,
        },
        optional: {
          format:         BsFormatType,
        },
        reference_id:     '_delete-highlight'
      }
    end

end

__loading_end(__FILE__)
