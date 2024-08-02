# app/records/ia_download/record/response_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A response from an Internet Archive "Printdisabled Unencrypted Ebook API"
# :json_only request.
#
class IaDownload::Record::ResponseRecord < Ingest::Api::Record

  include IaDownload::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :status, Integer
    has_one :message
  end

end

__loading_end(__FILE__)
