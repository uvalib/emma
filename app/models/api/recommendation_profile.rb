# app/models/api/recommendation_profile.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/link_methods'
require_relative 'category'

# Api::RecommendationProfile
#
# @attr [Array<AllowsType>]     allows
# @attr [Array<String>]         excludedAuthors
# @attr [Array<Api::Category>]  excludedCategories
# @attr [Array<ContentWarning>] excludedContentWarnings
# @attr [Boolean]               includeGlobalCollection
# @attr [Array<String>]         includedAuthors
# @attr [Array<Api::Category>]  includedCategories
# @attr [Array<ContentWarning>] includedContentWarnings
# @attr [Array<Api::Link>]      links
# @attr [Gender]                narratorGender
# @attr [NarratorType]          narratorType
#
# @see https://apidocs.bookshare.org/reference/index.html#_recommendation_profile
#
class Api::RecommendationProfile < Api::Record::Base

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,                  AllowsType
    has_many  :excludedAuthors,         String
    has_many  :excludedCategories,      Api::Category
    has_many  :excludedContentWarnings, ContentWarning
    attribute :includeGlobalCollection, Boolean
    has_many  :includedAuthors,         String
    has_many  :includedCategories,      Api::Category
    has_many  :includedContentWarnings, ContentWarning
    has_many  :links,                   Api::Link
    attribute :narratorGender,          Gender
    attribute :narratorType,            NarratorType
  end

end

__loading_end(__FILE__)
