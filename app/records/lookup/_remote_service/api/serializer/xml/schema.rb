# app/records/lookup/_remote_service/api/serializer/xml/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# XML-specific definition overrides for serialization.
#
# @see Api::Serializer::Xml::Schema
#
module Lookup::RemoteService::Api::Serializer::Xml::Schema

  include Lookup::RemoteService::Api::Serializer::Schema
  include Api::Serializer::Xml::Schema

end

__loading_end(__FILE__)
