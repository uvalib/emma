# app/records/lookup/google_books/record/download.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Information about a volume's download license access restrictions.
#
# @attr [String]   kind
# @attr [String]   volumeId
# @attr [Boolean]  restricted
# @attr [Boolean]  deviceAllowed
# @attr [Boolean]  justAcquired
# @attr [Integer]  maxDownloadDevices
# @attr [Integer]  downloadsAcquired
# @attr [String]   nonce
# @attr [String]   source
# @attr [String]   reasonCode
# @attr [String]   message
# @attr [String]   signature
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
class Lookup::GoogleBooks::Record::Download < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :kind
    has_one :volumeId
    has_one :restricted,          Boolean
    has_one :deviceAllowed,       Boolean
    has_one :justAcquired,        Boolean
    has_one :maxDownloadDevices,  Integer
    has_one :downloadsAcquired,   Integer
    has_one :nonce
    has_one :source
    has_one :reasonCode
    has_one :message
    has_one :signature
  end

end

__loading_end(__FILE__)
