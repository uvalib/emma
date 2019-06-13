# app/models/api/category.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

require_relative 'link'
require_relative 'common/category_methods'

# Api::Category
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_category
#
class Api::Category < Api::Record::Base

  schema do
    attribute :categoryType, CategoryType
    attribute :description,  String
    has_many  :links,        Api::Link
    attribute :name,         String
  end

  include Api::Common::CategoryMethods

  # ===========================================================================
  # :section: Api::Common::CategoryMethods overrides
  # ===========================================================================

  public

  # Translate to Bookshare category if necessary; return *nil* if not
  # translatable.
  #
  # @return [String, nil]
  #
  # This method overrides
  # @see Api::Common::CategoryMethods#bookshare_category
  #
  def bookshare_category
    name.to_s unless categoryType.to_s.casecmp('Bookshare').nonzero?
  end

end

__loading_end(__FILE__)
