# app/records/lookup/world_cat/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# Lookup::WorldCat::Api::Record.
#
#--
# noinspection LongLine
#++
class Lookup::WorldCat::Api::Serializer < Lookup::RemoteService::Api::Serializer

  include Lookup::WorldCat::Api::Serializer::Schema
  include Lookup::WorldCat::Api::Serializer::Associations

end

__loading_end(__FILE__)
