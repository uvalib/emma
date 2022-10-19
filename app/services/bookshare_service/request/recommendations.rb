# app/services/bookshare_service/request/recommendations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::Recommendations
#
# == Usage Notes
#
# === From API section 2.12 (Recommendations):
# Recommendations represent titles that Bookshare recommends to a user based on
# their reading history.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::Recommendations

  include BookshareService::Common
  include BookshareService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myRecommendations
  #
  # == 2.12.1. Get my recommended titles
  # Get recommended titles for the requesting user.
  #
  # @param [Hash] opt                       Passed to #api.
  #
  # @option opt [String]  :start
  # @option opt [Integer] :limit
  #
  # @return [Bs::Message::RecommendedTitles]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-my-recommended-titles
  #
  def get_recommendations(**opt)
    # noinspection RubyMismatchedArgumentType
    opt = get_parameters(__method__, **opt)
    api(:get, 'myRecommendations', **opt)
    api_return(Bs::Message::RecommendedTitles)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
        },
        reference_id: '_get-my-recommended-titles'
      }
    end

end

__loading_end(__FILE__)
