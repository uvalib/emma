# app/records/lookup/crossref/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# Lookup::Crossref::Api::Record.
#
#--
# noinspection LongLine
#++
class Lookup::Crossref::Api::Serializer < Lookup::RemoteService::Api::Serializer

  include Lookup::Crossref::Api::Serializer::Schema
  include Lookup::Crossref::Api::Serializer::Associations

end

__loading_end(__FILE__)
