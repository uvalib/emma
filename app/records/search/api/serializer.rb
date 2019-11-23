# app/records/search/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# Search::Api::Record.
#
class Search::Api::Serializer < ::Api::Serializer

  include Search::Api::Serializer::Schema
  include Search::Api::Serializer::Associations

end

__loading_end(__FILE__)
