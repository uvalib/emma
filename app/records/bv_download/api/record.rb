# app/records/bv_download/api/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for objects relating to the UVALIB-hosted AWS S3 BiblioVault
# collections.
#
class BvDownload::Api::Record < Api::Record

  include BvDownload::Api::Common
  include BvDownload::Api::Schema
  include BvDownload::Api::Record::Schema
  include BvDownload::Api::Record::Associations

end

__loading_end(__FILE__)
