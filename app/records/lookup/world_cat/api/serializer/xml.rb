# app/records/lookup/world_cat/api/serializer/xml.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process XML data.
#
#--
# noinspection LongLine
#++
class Lookup::WorldCat::Api::Serializer::Xml < Lookup::RemoteService::Api::Serializer::Xml

  include Lookup::WorldCat::Api::Serializer::Xml::Schema
  include Lookup::WorldCat::Api::Serializer::Xml::Associations

end

__loading_end(__FILE__)
