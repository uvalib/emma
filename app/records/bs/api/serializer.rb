# app/records/bs/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# Bs::Api::Record.
#
class Bs::Api::Serializer < ::Api::Serializer

  include Bs::Api::Serializer::Schema
  include Bs::Api::Serializer::Associations

end

__loading_end(__FILE__)
