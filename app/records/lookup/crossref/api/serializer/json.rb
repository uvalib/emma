# app/records/lookup/crossref/api/serializer/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process JSON data.
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Api::Serializer::Json < Lookup::RemoteService::Api::Serializer::Json

  include Lookup::Crossref::Api::Serializer::Json::Schema
  include Lookup::Crossref::Api::Serializer::Json::Associations

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  def deserialize(data, method: :from_json)
    super
  end

end

__loading_end(__FILE__)
