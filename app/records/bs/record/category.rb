# app/records/bs/record/category.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Category
#
# @attr [CategoryType]            categoryType
# @attr [String]                  description
# @attr [Array<Bs::Record::Link>] links
# @attr [String]                  name
#
# @see https://apidocs.bookshare.org/reference/index.html#_category
#
class Bs::Record::Category < Bs::Api::Record

  include Bs::Shared::CategoryMethods
  include Bs::Shared::LinkMethods

  schema do
    attribute :categoryType, CategoryType
    attribute :description,  String
    has_many  :links,        Bs::Record::Link
    attribute :name,         String
  end

  # ===========================================================================
  # :section: Bs::Shared::CategoryMethods overrides
  # ===========================================================================

  public

  # Translate to Bookshare category if necessary.
  #
  # @return [String]
  # @return [nil]                     If not translatable.
  #
  # This method overrides
  # @see Bs::Shared::CategoryMethods#bookshare_category
  #
  def bookshare_category
    # noinspection RubyNilAnalysis
    name.to_s if categoryType.to_s.casecmp('Bookshare').zero?
  end

end

__loading_end(__FILE__)
