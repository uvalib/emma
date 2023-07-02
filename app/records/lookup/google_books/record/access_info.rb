# app/records/lookup/google_books/record/access_info.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Any information about a volume related to reading or obtaining that volume
# text. This information can depend on country (books may be public domain in
# one country but not in another, e.g.).
#
# @attr [String]   country
# @attr [String]   viewability              %w(... PARTIAL ALL_PAGES NO_PAGES UNKNOWN)
# @attr [Format]   epub
# @attr [Format]   pdf
# @attr [Boolean]  embeddable
# @attr [Boolean]  publicDomain
# @attr [String]   textToSpeechPermission   %w(ALLOWED ALLOWED_FOR_ACCESSIBILITY NOT_ALLOWED)
# @attr [String]   webReaderLink
# @attr [Download] downloadAccess
#
# === Observed but not documented
#
# @attr [String]   accessViewStatus         %w(... FULL_PUBLIC_DOMAIN SAMPLE NONE)
# @attr [Boolean]  quoteSharingAllowed
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
#--
# noinspection LongLine
#++
class Lookup::GoogleBooks::Record::AccessInfo < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::DateMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :country
    has_one :viewability
    has_one :epub,                    Lookup::GoogleBooks::Record::Format
    has_one :pdf,                     Lookup::GoogleBooks::Record::Format
    has_one :embeddable,              Boolean
    has_one :publicDomain,            Boolean
    has_one :textToSpeechPermission
    has_one :webReaderLink
    has_one :downloadAccess,          Lookup::GoogleBooks::Record::Download

    # === Observed but not documented

    has_one :accessViewStatus
    has_one :quoteSharingAllowed,     Boolean
  end

end

__loading_end(__FILE__)
