# app/records/lookup/_remote_service/api/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for objects that interact with the external service API,
# either to be initialized through de-serialized data received from the API or
# to be serialized into data to be sent to the API.
#
class Lookup::RemoteService::Api::Record < Api::Record

  include Lookup::RemoteService::Api::Common
  include Lookup::RemoteService::Api::Schema
  include Lookup::RemoteService::Api::Record::Schema
  include Lookup::RemoteService::Api::Record::Associations

end

__loading_end(__FILE__)
