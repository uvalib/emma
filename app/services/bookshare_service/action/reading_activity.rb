# app/services/bookshare_service/action/reading_activity.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Action::ReadingActivity
#
# == Usage Notes
#
# === From API section 2.9 (Reading Activity):
# Reading activity refers to a set of events that mark a user’s progress
# through a title. These events are location-based, referring to a span of text
# that could be a page, chapter, or an arbitrary set of continuous text.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Action::ReadingActivity

  include BookshareService::Common
  include BookshareService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == POST /v2/readingEvents
  #
  # == 2.9.1. Submit a reading activity event
  # Submit reading activity events that mark different types of reading
  # activity.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]       :bookshareId                          *REQUIRED*
  # @option opt [BsFormatType] :format                               *REQUIRED*
  # @option opt [String]       :location                             *REQUIRED*
  # @option opt [String]       :locationDescription
  # @option opt [Integer]      :metric                               *REQUIRED*
  # @option opt [BsMetricType] :metricType                           *REQUIRED*
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_post-reading-activity-event
  #
  def create_reading_event(**opt)
    opt = get_parameters(__method__, **opt)
    api(:post, 'readingEvents', **opt)
    api_return(Bs::Message::StatusModel)
  end
    .tap do |method|
      add_api method => {
        alias: {
          fmt:                  :format,
        },
        required: {
          bookshareId:          String,
          format:               BsFormatType,
          location:             String,
          metric:               Integer,
          metricType:           BsMetricType,
        },
        optional: {
          locationDescription:  String,
        },
        reference_id:           '_post-reading-activity-event'
      }
    end

  # == GET /v2/myReadingPosition/(bookshareId)/(format)
  #
  # == 2.9.2. Get my reading position
  # Get my reading position for a specific title format.
  #
  # @param [String]       bookshareId
  # @param [BsFormatType] format
  # @param [Hash]         opt         Passed to #api.
  #
  # @return [Bs::Message::ReadingPosition]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-reading-position
  #
  def get_reading_position(bookshareId:, format:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myReadingPosition', bookshareId, format, **opt)
    api_return(Bs::Message::ReadingPosition)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      BsFormatType,
        },
        reference_id:  '_get-reading-position'
      }
    end

end

__loading_end(__FILE__)
