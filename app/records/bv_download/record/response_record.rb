# app/records/bv_download/record/response_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A response from the UVALIB service which hosts the BiblioVault collections.
#
class BvDownload::Record::ResponseRecord < Ingest::Api::Record

  include BvDownload::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :status, Integer
    has_one :message
  end

end

__loading_end(__FILE__)
