# app/records/bs/record/category.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Category
#
# @attr [CategoryType]            categoryType
# @attr [String]                  code
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
    has_one   :categoryType, CategoryType
    has_one   :code
    has_one   :description
    has_many  :links,        Bs::Record::Link
    has_one   :name
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
  def bookshare_category
    # noinspection RubyNilAnalysis
    name.to_s if categoryType.to_s.casecmp?('Bookshare')
  end

end

__loading_end(__FILE__)
