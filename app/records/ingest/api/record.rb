# app/records/ingest/api/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for objects that interact with the EMMA Unified Ingest API,
# either to be initialized through de-serialized data received from the API or
# to be serialized into data to be sent to the API.
#
class Ingest::Api::Record < Api::Record

  include Ingest::Api::Common
  include Ingest::Api::Schema
  include Ingest::Api::Record::Schema
  include Ingest::Api::Record::Associations

end

__loading_end(__FILE__)
