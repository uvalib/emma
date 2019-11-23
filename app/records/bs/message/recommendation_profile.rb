# app/records/bs/message/recommendation_profile.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::RecommendationProfile
#
# @attr [Array<AllowsType>]           allows
# @attr [Array<String>]               excludedAuthors
# @attr [Array<Bs::Record::Category>] excludedCategories
# @attr [Array<ContentWarning>]       excludedContentWarnings
# @attr [Boolean]                     includeGlobalCollection
# @attr [Array<String>]               includedAuthors
# @attr [Array<Bs::Record::Category>] includedCategories
# @attr [Array<ContentWarning>]       includedContentWarnings
# @attr [Array<Bs::Record::Link>]     links
# @attr [Gender]                      narratorGender
# @attr [NarratorType]                narratorType
# @attr [Integer]                     readingAge
#
# @see https://apidocs.bookshare.org/reference/index.html#_recommendation_profile
#
# NOTE: This duplicates:
# @see Bs::Record::RecommendationProfile
#
# noinspection DuplicatedCode
class Bs::Message::RecommendationProfile < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,                  AllowsType
    has_many  :excludedAuthors,         String
    has_many  :excludedCategories,      Bs::Record::Category
    has_many  :excludedContentWarnings, ContentWarning
    attribute :includeGlobalCollection, Boolean
    has_many  :includedAuthors,         String
    has_many  :includedCategories,      Bs::Record::Category
    has_many  :includedContentWarnings, ContentWarning
    has_many  :links,                   Bs::Record::Link
    attribute :narratorGender,          Gender
    attribute :narratorType,            NarratorType
    attribute :readingAge,              Integer
  end

end

__loading_end(__FILE__)
