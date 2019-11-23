# app/records/search/api/serializer/xml.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process XML data.
#
class Search::Api::Serializer::Xml < ::Api::Serializer::Xml

  include Search::Api::Serializer::Xml::Schema
  include Search::Api::Serializer::Xml::Associations

end

__loading_end(__FILE__)
