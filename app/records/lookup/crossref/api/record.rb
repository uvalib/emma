# app/records/lookup/crossref/api/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for objects that interact with the external service API,
# either to be initialized through de-serialized data received from the API or
# to be serialized into data to be sent to the API.
#
class Lookup::Crossref::Api::Record < Lookup::RemoteService::Api::Record

  include Lookup::Crossref::Api::Common
  include Lookup::Crossref::Api::Schema
  include Lookup::Crossref::Api::Record::Schema
  include Lookup::Crossref::Api::Record::Associations

end

__loading_end(__FILE__)
