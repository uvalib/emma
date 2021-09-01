# app/records/bs/message/active_book_profile.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ActiveBookProfile
#
# @attr [Array<BsAllowsType>]               allows
# @attr [Array<Bs::Record::Link>]           links
# @attr [Integer]                           maxContributions
# @attr [Bs::Record::ActiveBookPreferences] preferences
# @attr [Bs::Record::RecommendationProfile] recommendationProfile
# @attr [Bs::Record::ReadingListUserView]   requestList
# @attr [Boolean]                           useRecommendations
# @attr [Boolean]                           useRequestList
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_book_profile
#
class Bs::Message::ActiveBookProfile < Bs::Api::Message

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many  :allows,                BsAllowsType
    has_many  :links,                 Bs::Record::Link
    has_one   :maxContributions,      Integer
    has_one   :preferences,           Bs::Record::ActiveBookPreferences
    has_one   :recommendationProfile, Bs::Record::RecommendationProfile
    has_one   :requestList,           Bs::Record::ReadingListUserView
    has_one   :useRecommendations,    Boolean
    has_one   :useRequestList,        Boolean
  end

end

__loading_end(__FILE__)
