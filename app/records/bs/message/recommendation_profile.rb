# app/records/bs/message/recommendation_profile.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::RecommendationProfile
#
# @see Bs::Record::RecommendationProfile
#
class Bs::Message::RecommendationProfile < Bs::Api::Message

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::RecommendationProfile

end

__loading_end(__FILE__)
