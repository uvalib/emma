# app/records/bs/record/recommendation_profile.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::RecommendationProfile
#
# @attr [Array<BsAllowsType>]         allows
# @attr [Array<String>]               excludedAuthors
# @attr [Array<Bs::Record::Category>] excludedCategories
# @attr [Array<BsContentWarning>]     excludedContentWarnings
# @attr [Boolean]                     includeGlobalCollection
# @attr [Array<String>]               includedAuthors
# @attr [Array<Bs::Record::Category>] includedCategories
# @attr [Array<BsContentWarning>]     includedContentWarnings
# @attr [Array<Bs::Record::Link>]     links
# @attr [BsGender]                    narratorGender
# @attr [BsNarratorType]              narratorType
# @attr [Integer]                     readingAge
#
# @see https://apidocs.bookshare.org/reference/index.html#_recommendation_profile
#
class Bs::Record::RecommendationProfile < Bs::Api::Record

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many  :allows,                  BsAllowsType
    has_many  :excludedAuthors
    has_many  :excludedCategories,      Bs::Record::Category
    has_many  :excludedContentWarnings, BsContentWarning
    has_one   :includeGlobalCollection, Boolean
    has_many  :includedAuthors
    has_many  :includedCategories,      Bs::Record::Category
    has_many  :includedContentWarnings, BsContentWarning
    has_many  :links,                   Bs::Record::Link
    has_one   :narratorGender,          BsGender
    has_one   :narratorType,            BsNarratorType
    has_one   :readingAge,              Integer
  end

end

__loading_end(__FILE__)
