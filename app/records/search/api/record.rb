# app/records/search/api/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for objects that interact with the Bookshare API, either to be
# initialized through de-serialized data received from the API or to be
# serialized into data to be sent to the API.
#
class Search::Api::Record < ::Api::Record

  include Search::Api::Common
  include Search::Api::Schema
  include Search::Api::Record::Schema
  include Search::Api::Record::Associations

end

__loading_end(__FILE__)
