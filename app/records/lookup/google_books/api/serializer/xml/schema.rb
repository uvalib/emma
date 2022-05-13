# app/records/lookup/google_books/api/serializer/xml/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# XML-specific definition overrides for serialization.
#
# @see Lookup::RemoteService::Api::Serializer::Xml::Schema
#
module Lookup::GoogleBooks::Api::Serializer::Xml::Schema

  include Lookup::GoogleBooks::Api::Serializer::Schema
  include Lookup::RemoteService::Api::Serializer::Xml::Schema

end

__loading_end(__FILE__)
