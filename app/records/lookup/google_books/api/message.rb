# app/records/lookup/google_books/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for inbound messages from the external service API.
#
class Lookup::GoogleBooks::Api::Message < Lookup::GoogleBooks::Api::Record

  include Lookup::RemoteService::Api::Message

  include Lookup::GoogleBooks::Shared::ResponseMethods

end

__loading_end(__FILE__)
