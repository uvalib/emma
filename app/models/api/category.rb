# app/models/api/category.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/category_methods'
require_relative 'common/link_methods'

# Api::Category
#
# @attr [CategoryType]     categoryType
# @attr [String]           description
# @attr [Array<Api::Link>] links
# @attr [String]           name
#
# @see https://apidocs.bookshare.org/reference/index.html#_category
#
class Api::Category < Api::Record::Base

  include Api::Common::CategoryMethods
  include Api::Common::LinkMethods

  schema do
    attribute :categoryType, CategoryType
    attribute :description,  String
    has_many  :links,        Api::Link
    attribute :name,         String
  end

  # ===========================================================================
  # :section: Api::Common::CategoryMethods overrides
  # ===========================================================================

  public

  # Translate to Bookshare category if necessary.
  #
  # @return [String]
  # @return [nil]                     If not translatable.
  #
  # This method overrides
  # @see Api::Common::CategoryMethods#bookshare_category
  #
  def bookshare_category
    name.to_s unless categoryType.to_s.casecmp('Bookshare').nonzero?
  end

end

__loading_end(__FILE__)
