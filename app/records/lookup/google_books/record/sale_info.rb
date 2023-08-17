# app/records/lookup/google_books/record/sale_info.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Any information about a volume related to the eBookstore and/or
# purchase-ability. This information can depend on the country where the
# request originates from (i.e., books may not be for sale in certain
# countries).
#
# @attr [String]   country
# @attr [String]   saleability        %w[... FREE FOR_SALE NOT_FOR_SALE]
# @attr [Boolean]  isEbook
# @attr [Price]    listPrice
# @attr [Price]    retailPrice
# @attr [String]   buyLink
# @attr [DateTime] onSaleDate
#
# === Observed but not documented
#
# @attr [Hash]     offers
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
class Lookup::GoogleBooks::Record::SaleInfo < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::DateMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :country
    has_one :saleability
    has_one :isEbook,       Boolean
    has_one :listPrice,     Lookup::GoogleBooks::Record::Price
    has_one :retailPrices,  Lookup::GoogleBooks::Record::Price
    has_one :buyLink
    has_one :onSaleDate,    DateTime

    # === Observed but not documented

    has_one :offers
  end

end

__loading_end(__FILE__)
