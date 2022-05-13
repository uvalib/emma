# app/records/lookup/google_books/record/price.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Price.
#
# @attr [Float]  amount
# @attr [String] currencyCode   %w(... USD)
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
class Lookup::GoogleBooks::Record::Price < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :amount,      Float
    has_one :currencyCode
  end

end

__loading_end(__FILE__)
