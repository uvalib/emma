# app/records/lookup/crossref/api/serializer/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common definitions for serialization.
#
module Lookup::Crossref::Api::Serializer::Schema

  include Emma::Json

  include Lookup::Crossref::Api::Schema
  include Lookup::RemoteService::Api::Serializer::Schema

  # ===========================================================================
  # :section: Api::Serializer overrides
  # ===========================================================================

  public

  # This override is a kludge to transform "dasherized" keys into a form that
  # can be used to create valid Rails attributes as defined in the schema block
  # of the message or record class.
  #
  # E.g.:
  # * '{ "isbn-type" : [...] }' becomes '{ "isbn_type" : [...] }'
  # * '{ "DOI" : "..." }'       becomes '{ "doi" : "..." }'
  #
  # @param [String, Hash] data
  # @param [Symbol, Proc] method
  #
  # @return [Api::Record]
  # @return [nil]
  #
  def deserialize(data, method: nil)
    data = safe_json_parse(data, log: false, symbolize_keys: false)
    data = data.deep_transform_keys!(&:underscore).to_json if data.is_a?(Hash)
    super
  end

end

__loading_end(__FILE__)
