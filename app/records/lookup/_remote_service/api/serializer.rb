# app/records/lookup/_remote_service/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# Lookup::RemoteService::Api::Record.
#
class Lookup::RemoteService::Api::Serializer < Api::Serializer

  include Lookup::RemoteService::Api::Serializer::Schema
  include Lookup::RemoteService::Api::Serializer::Associations

end

__loading_end(__FILE__)
