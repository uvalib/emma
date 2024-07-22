# app/records/search/api/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Values related to the details of serialization/de-serialization.
#
# @see Api::Schema
#
module Search::Api::Schema

  include Search::Api::Common
  include Api::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # service_name
  #
  # @return [String]
  #
  def service_name
    'Search'
  end

end

__loading_end(__FILE__)
