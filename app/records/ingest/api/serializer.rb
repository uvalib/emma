# app/records/ingest/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# Ingest::Api::Record.
#
class Ingest::Api::Serializer < Api::Serializer

  include Ingest::Api::Serializer::Schema
  include Ingest::Api::Serializer::Associations

end

__loading_end(__FILE__)
