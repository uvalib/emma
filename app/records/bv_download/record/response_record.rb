# app/records/bv_download/record/response_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A response from the AWS S3 bucket containing the EMMA publisher collections.
#
# @note This is unused and may go away.
#
class BvDownload::Record::ResponseRecord < Ingest::Api::Record

  include BvDownload::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    # No fields yet
  end

end

__loading_end(__FILE__)
