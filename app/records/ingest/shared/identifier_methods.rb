# app/records/ingest/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module Ingest::Shared::IdentifierMethods

  include Api::Shared::IdentifierMethods
  include Ingest::Shared::CommonMethods

  # ===========================================================================
  # :section: Api::Shared::IdentifierMethods overrides
  # ===========================================================================

  public

  # Produce standard identifiers of the form "(prefix):(value)", allowing
  # invalid identifiers with the proper form but rejecting ones that don't.
  #
  # @param [String, PublicationIdentifier, Array, nil] values
  #
  # @return [Array<String>]
  #
  def normalize_identifiers(values)
    PublicationIdentifier.objects(values).reject { |id|
      id.nil? || id.identifier_subclass.identifier(id).nil?
    }.map(&:to_s).uniq
  end

end

__loading_end(__FILE__)
