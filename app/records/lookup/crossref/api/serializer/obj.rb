# app/records/lookup/crossref/api/serializer/obj.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Ruby (hash) object representation.
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Api::Serializer::Obj < Lookup::RemoteService::Api::Serializer::Obj

  include Lookup::Crossref::Api::Serializer::Obj::Schema
  include Lookup::Crossref::Api::Serializer::Obj::Associations

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  def deserialize(data, method: :from_obj)
    super
  end

end

__loading_end(__FILE__)
