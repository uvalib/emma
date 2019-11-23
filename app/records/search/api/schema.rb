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
  include ::Api::Schema

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

  # A table of schema property enumeration types mapped to literals which are
  # their default values.
  #
  # @return [Hash{Symbol=>Object}]
  #
  def enumeration_defaults
    @enumeration_defaults ||=
      Search::ENUMERATIONS.transform_values { |prop| prop[:default] || '' }
  end

  # The enumeration types that may be given as the second argument to
  # #attribute, #has_one, or #has_many definitions.
  #
  # @return [Array<Symbol>]
  #
  def enumeration_types
    @enumeration_types ||= enumeration_defaults.keys
  end

end

__loading_end(__FILE__)
