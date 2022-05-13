# app/records/lookup/world_cat/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for inbound messages from the external service API.
#
class Lookup::WorldCat::Api::Message < Lookup::WorldCat::Api::Record

  include Lookup::RemoteService::Api::Message

  include Lookup::WorldCat::Shared::ResponseMethods

end

__loading_end(__FILE__)
