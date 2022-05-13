# app/records/lookup/crossref/api/serializer/xml.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process XML data.
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Api::Serializer::Xml < Lookup::RemoteService::Api::Serializer::Xml

  include Lookup::Crossref::Api::Serializer::Xml::Schema
  include Lookup::Crossref::Api::Serializer::Xml::Associations

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  def deserialize(data, method: :from_xml)
    super
  end

end

__loading_end(__FILE__)
