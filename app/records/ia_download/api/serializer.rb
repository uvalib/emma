# app/records/ia_download/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# IaDownload::Api::Record.
#
class IaDownload::Api::Serializer < Api::Serializer

  include IaDownload::Api::Serializer::Schema
  include IaDownload::Api::Serializer::Associations

end

__loading_end(__FILE__)
