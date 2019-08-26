# app/models/api_active_book_profile.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/active_book_preferences'
require_relative 'api/recommendation_profile'

# ApiActiveBookProfile
#
# @attr [Array<AllowsType>]          allows
# @attr [Array<Api::Link>]           links
# @attr [Integer]                    maxContributions
# @attr [Api::ActiveBookPreferences] preferences
# @attr [Api::RecommendationProfile] recommendationProfile
# @attr [Boolean]                    useRecommendations
# @attr [Boolean]                    useRequestList
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_book_profile
#
class ApiActiveBookProfile < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,                AllowsType
    has_many  :links,                 Api::Link
    attribute :maxContributions,      Integer
    has_one   :preferences,           Api::ActiveBookPreferences
    has_one   :recommendationProfile, Api::RecommendationProfile
    attribute :useRecommendations,    Boolean
    attribute :useRequestList,        Boolean
  end

end

__loading_end(__FILE__)
