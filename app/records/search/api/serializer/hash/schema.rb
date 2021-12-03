# app/records/search/api/serializer/hash/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Hash-specific definition overrides for serialization.
#
# @see Api::Serializer::Hash::Schema
#
#--
# noinspection RubyResolve
#++
module Search::Api::Serializer::Hash::Schema

  include Search::Api::Serializer::Schema
  include Api::Serializer::Hash::Schema

end

__loading_end(__FILE__)
