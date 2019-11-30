# app/records/search/api/serializer/xml/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# XML-specific definition overrides for serialization.
#
# @see Api::Serializer::Xml::Schema
#
module Search::Api::Serializer::Xml::Schema

  include Search::Api::Serializer::Schema
  include ::Api::Serializer::Xml::Schema

end

__loading_end(__FILE__)
