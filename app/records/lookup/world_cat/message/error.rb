# app/records/lookup/world_cat/message/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Lookup::WorldCat::Message::Error
#
# HTTP 401 - "Invalid authentication credentials"
#               XML
# HTTP 403 - "Unauthorized. Typically the key is over its quota"
#               No body?
# HTTP 405 - "Method not supported"
#                JSON not XML: '{ "summary" : (message), "value" : (HTML) }'
# HTTP 500 - "Something went wrong (hopefully rare) - please try again"
#                Empty JSON: '{}'
#
# @see https://developer.api.oclc.org/wcv1#operations-SRU-search-sru
#
class Lookup::WorldCat::Message::Error < Lookup::WorldCat::Api::Message

  include Lookup::WorldCat::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :code
    has_one :message
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def to_s
    message.to_s
  end

end

__loading_end(__FILE__)
