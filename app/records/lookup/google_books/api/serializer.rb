# app/records/lookup/google_books/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# Lookup::GoogleBooks::Api::Record.
#
#--
# noinspection LongLine
#++
class Lookup::GoogleBooks::Api::Serializer < Lookup::RemoteService::Api::Serializer

  include Lookup::GoogleBooks::Api::Serializer::Schema
  include Lookup::GoogleBooks::Api::Serializer::Associations

end

__loading_end(__FILE__)
