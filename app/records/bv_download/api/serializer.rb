# app/records/bv_download/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# BvDownload::Api::Record.
#
class BvDownload::Api::Serializer < Api::Serializer

  include BvDownload::Api::Serializer::Schema
  include BvDownload::Api::Serializer::Associations

end

__loading_end(__FILE__)
