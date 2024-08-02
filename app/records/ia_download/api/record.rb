# app/records/ia_download/api/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for objects that interact with the EMMA Unified IaDownload API,
# either to be initialized through de-serialized data received from the API or
# to be serialized into data to be sent to the API.
#
class IaDownload::Api::Record < Api::Record

  include IaDownload::Api::Common
  include IaDownload::Api::Schema
  include IaDownload::Api::Record::Schema
  include IaDownload::Api::Record::Associations

end

__loading_end(__FILE__)
