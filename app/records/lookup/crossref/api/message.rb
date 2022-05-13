# app/records/lookup/crossref/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for inbound messages from the external service API.
#
class Lookup::Crossref::Api::Message < Lookup::Crossref::Api::Record

  include Lookup::RemoteService::Api::Message

  include Lookup::Crossref::Shared::ResponseMethods

end

__loading_end(__FILE__)
